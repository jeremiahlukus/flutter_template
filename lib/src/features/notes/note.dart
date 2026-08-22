import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_template/src/database/app_database.dart';

/// A single note. The reference domain object for this template.
///
/// Deliberately boring: an id, two text fields, and the two pieces of metadata
/// every offline-first record needs ([updatedAt] for conflict resolution,
/// [pendingSync] for "the server hasn't seen this yet").
///
/// **[updatedAt] is always UTC.** Firestore's `Timestamp.toDate()` hands back a
/// *local* `DateTime`, so a naive round-trip through Firestore returns a value
/// that is the same instant but compares unequal. Every boundary in this class
/// normalises to UTC to keep equality — and therefore change detection —
/// meaningful.
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.pendingSync = false,
  });

  factory Note.fromRow(NoteRow row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    updatedAt: row.updatedAt.toUtc(),
    pendingSync: row.pendingSync,
  );

  /// Reads a Firestore document. Tolerates missing *and mistyped* fields rather
  /// than throwing, because one bad document should not break the whole list.
  ///
  /// The type tests are `is` checks rather than casts on purpose: a stray number
  /// where a string belongs is data to ignore, not an exception to propagate.
  factory Note.fromFirestore(String id, Map<String, dynamic> data) => Note(
    id: id,
    title: data['title'] is String ? data['title'] as String : '',
    body: data['body'] is String ? data['body'] as String : '',
    updatedAt: switch (data['updatedAt']) {
      final Timestamp t => t.toDate().toUtc(),
      final DateTime d => d.toUtc(),
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    },
  );

  /// Length limits, and the single source of truth for them.
  ///
  /// The same numbers are enforced by the Drift column definition and by
  /// `firestore.rules`. Three layers on purpose — but the *client* has to check
  /// first, because the other two fail badly: Drift throws
  /// `InvalidDataException` out of the save, and the rules reject the write
  /// while the local copy stays queued forever with nothing to explain it.
  static const maxTitleLength = 200;

  /// ~100KB of text. Generous for a note, bounded enough that one document
  /// cannot blow a Firestore write limit.
  static const maxBodyLength = 100000;

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool pendingSync;

  /// Which limit this note breaks, or null when it is within them.
  ///
  /// Checked before persisting, so an over-long note is reported to the user
  /// rather than crashing the save or silently never syncing.
  NoteLimit? get exceededLimit {
    if (title.length > maxTitleLength) return NoteLimit.title;
    if (body.length > maxBodyLength) return NoteLimit.body;
    return null;
  }

  bool get isWithinLimits => exceededLimit == null;

  /// First line of the body, for list subtitles.
  String get preview {
    final firstLine = body
        .split('\n')
        .firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => '',
        );
    return firstLine.length <= 80
        ? firstLine
        : '${firstLine.substring(0, 79)}…';
  }

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  /// Title as shown in lists — never blank, so rows keep a stable height.
  ///
  /// Takes the fallback as an argument rather than hard-coding one: this is a
  /// domain object and has no `BuildContext`, so the localised placeholder has
  /// to come from the UI layer.
  String titleOr(String fallback) =>
      title.trim().isEmpty ? fallback : title.trim();

  /// Non-localised title, for logs and `toString`. Screens use [titleOr].
  String get displayTitle => titleOr('Untitled note');

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'body': body,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  NoteRow toRow() => NoteRow(
    id: id,
    title: title,
    body: body,
    updatedAt: updatedAt,
    pendingSync: pendingSync,
  );

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? pendingSync,
  }) => Note(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.updatedAt == updatedAt &&
      other.pendingSync == pendingSync;

  @override
  int get hashCode => Object.hash(id, title, body, updatedAt, pendingSync);

  @override
  String toString() => 'Note($id, "$displayTitle", pending: $pendingSync)';
}

/// Which of a note's length limits was exceeded.
enum NoteLimit {
  title,
  body;

  /// The limit's value, for a message that tells the user the actual number.
  int get max => switch (this) {
    NoteLimit.title => Note.maxTitleLength,
    NoteLimit.body => Note.maxBodyLength,
  };
}
