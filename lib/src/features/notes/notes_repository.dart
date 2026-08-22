import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/notes/note.dart';

class NotesFailure implements Exception {
  const NotesFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'NotesFailure($code): $message';
}

/// Offline-first notes storage.
///
/// Reads always come from Drift so the UI never waits on the network. Writes go
/// to Drift first (marked `pendingSync`), then to Firestore; only a confirmed
/// Firestore write clears the flag. [sync] reconciles in both directions.
///
/// The invariant worth protecting: a local edit is never lost because a remote
/// pull happened to land first. [AppDatabase.replaceNotes] enforces it.
class NotesRepository {
  NotesRepository({
    required FirebaseFirestore firestore,
    required AppDatabase database,
    required AnalyticsService analytics,
    required String userId,
    DateTime Function() clock = DateTime.now,
  }) : _firestore = firestore,
       _db = database,
       _analytics = analytics,
       _userId = userId,
       _clock = clock;

  final FirebaseFirestore _firestore;
  final AppDatabase _db;
  final AnalyticsService _analytics;
  final String _userId;
  final DateTime Function() _clock;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('notes');

  /// Firestore documents fetched per sync page.
  ///
  /// Bounded so a large collection does not arrive as one enormous read — both
  /// for memory and because Firestore bills per document read either way.
  static const syncPageSize = 200;

  /// The local cache, which is what the UI renders.
  ///
  /// Pass [limit] to bound the query; see `PageWindow` for why the UI grows a
  /// window rather than accumulating pages.
  Stream<List<Note>> watchNotes({int? limit}) => _db
      .watchNotes(limit: limit)
      .map((rows) => rows.map(Note.fromRow).toList());

  Future<List<Note>> localNotes() async =>
      (await _db.allNotes()).map(Note.fromRow).toList();

  Future<Note?> find(String id) async {
    final row = await _db.findNote(id);
    return row == null ? null : Note.fromRow(row);
  }

  /// Creates or updates a note.
  ///
  /// Returns immediately after the local write succeeds. A Firestore failure
  /// leaves the note in the cache with `pendingSync: true` rather than
  /// propagating — the next [sync] retries it.
  Future<Note> save(Note note) async {
    // Checked before anything is written. Letting this reach Drift throws
    // `InvalidDataException` straight out of the save; letting it reach
    // Firestore leaves the note queued forever with nothing to explain it.
    final violation = note.exceededLimit;
    if (violation != null) {
      throw NotesFailure(
        'too-long',
        '${violation.name} exceeds ${violation.max} characters.',
      );
    }

    final staged = note.copyWith(updatedAt: _clock(), pendingSync: true);
    await _db.upsertNote(staged.toRow());

    try {
      await _collection.doc(staged.id).set(staged.toFirestore());
      final confirmed = staged.copyWith(pendingSync: false);
      await _db.upsertNote(confirmed.toRow());
      await _analytics.logEvent('note_saved', parameters: {'id': staged.id});
      return confirmed;
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Note ${staged.id} saved locally but not remotely; queued for sync',
        error: error,
        stackTrace: stackTrace,
      );
      return staged;
    }
  }

  /// Deletes locally and remotely. A remote failure still removes the local
  /// copy — a resurrected note is more confusing than a slow tombstone.
  Future<void> delete(String id) async {
    await _db.deleteNote(id);
    try {
      await _collection.doc(id).delete();
      await _analytics.logEvent('note_deleted', parameters: {'id': id});
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Note $id deleted locally but not remotely',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Pushes queued local writes, then pulls the server's view into the cache.
  ///
  /// Push happens first so a freshly-created note is not clobbered by a pull
  /// that predates it.
  Future<SyncReport> sync() async {
    var pushed = 0;
    var failed = 0;

    for (final row in await _db.pendingNotes()) {
      final note = Note.fromRow(row);
      try {
        await _collection.doc(note.id).set(note.toFirestore());
        await _db.upsertNote(note.copyWith(pendingSync: false).toRow());
        pushed++;
      } catch (error) {
        AppLogger.instance.w('Failed to push note ${note.id}: $error');
        failed++;
      }
    }

    var pulled = 0;
    try {
      // Paged so a big collection does not arrive in one read.
      //
      // Keyset pagination on the document id, rather than `startAfterDocument`.
      // Two reasons: the cursor is a plain string so no snapshot has to be held
      // across pages, and ordering by id is stable while the pull is in flight —
      // a note edited mid-sync would move under an `updatedAt` cursor and could
      // be skipped or read twice.
      final remote = <Note>[];
      String? after;

      while (true) {
        Query<Map<String, dynamic>> query = _collection;
        if (after != null) {
          query = query.where(FieldPath.documentId, isGreaterThan: after);
        }
        final page = await query
            .orderBy(FieldPath.documentId)
            .limit(syncPageSize)
            .get();

        if (page.docs.isEmpty) break;
        remote.addAll(
          page.docs.map((doc) => Note.fromFirestore(doc.id, doc.data())),
        );
        if (page.docs.length < syncPageSize) break;
        after = page.docs.last.id;
      }

      await _db.replaceNotes(remote.map((n) => n.toRow()).toList());
      pulled = remote.length;
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Note pull failed; cache left untouched',
        error: error,
        stackTrace: stackTrace,
      );
      await _analytics.logEvent('note_sync_failed');
      return SyncReport(pushed: pushed, pulled: 0, failed: failed, ok: false);
    }

    await _analytics.logEvent(
      'note_sync',
      parameters: {
        'pushed': pushed,
        'pulled': pulled,
      },
    );
    return SyncReport(
      pushed: pushed,
      pulled: pulled,
      failed: failed,
      ok: failed == 0,
    );
  }

  /// Builds a new, empty note with a Firestore-generated id.
  Note draft() => Note(
    id: _collection.doc().id,
    title: '',
    body: '',
    updatedAt: _clock(),
  );

  /// Drops the local cache. Call on sign-out so the next user sees nothing.
  Future<void> clearCache() => _db.clearNotes();
}

/// Outcome of a [NotesRepository.sync] pass.
class SyncReport {
  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.failed,
    required this.ok,
  });

  final int pushed;
  final int pulled;
  final int failed;
  final bool ok;

  @override
  String toString() =>
      'SyncReport(pushed: $pushed, pulled: $pulled, failed: $failed, ok: $ok)';
}
