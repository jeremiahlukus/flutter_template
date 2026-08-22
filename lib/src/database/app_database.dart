import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'flutter_template'));

  /// In-memory database for tests. Each call is an isolated, empty schema.
  factory AppDatabase.memory() => AppDatabase(inMemoryExecutor());

  @override
  int get schemaVersion => 1;

  /// Store timestamps as ISO-8601 UTC text rather than unix seconds.
  ///
  /// The default integer format silently truncates to whole seconds and loses
  /// the UTC flag, which makes `updatedAt` comparisons — the basis of sync
  /// conflict resolution — unreliable.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Drift disables foreign keys by default; the app relies on them.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // --- Notes -----------------------------------------------------------------

  /// Watches the most recent [limit] notes, newest first.
  ///
  /// A *growing window* rather than page-by-page accumulation: Drift streams
  /// re-emit on every write, so a paged accumulator would fight the reactive
  /// query and drift out of sync. Raising the limit re-runs one bounded query
  /// and keeps the list live — which is what an offline-first list wants.
  ///
  /// Null means no limit, which is only appropriate for sync and tests.
  Stream<List<NoteRow>> watchNotes({int? limit}) {
    final query = select(notes)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  /// Total cached notes, so the UI knows when it has reached the end.
  Future<int> countNotes() async {
    final count = notes.id.count();
    final row = await (selectOnly(notes)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchNoteCount() {
    final count = notes.id.count();
    return (selectOnly(
      notes,
    )..addColumns([count])).watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<NoteRow>> allNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Future<NoteRow?> findNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertNote(NoteRow row) =>
      into(notes).insertOnConflictUpdate(row);

  Future<int> deleteNote(String id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();

  Future<List<NoteRow>> pendingNotes() =>
      (select(notes)..where((t) => t.pendingSync.equals(true))).get();

  /// Atomically replaces the cache with [rows], preserving unsynced local work.
  ///
  /// Rows still marked [Notes.pendingSync] are kept: they represent edits the
  /// server has not seen, and clobbering them would silently lose user data.
  Future<void> replaceNotes(List<NoteRow> rows) => transaction(() async {
    final keep = await pendingNotes();
    final keepIds = keep.map((r) => r.id).toSet();
    await (delete(notes)..where((t) => t.pendingSync.equals(false))).go();
    await batch((b) {
      b.insertAllOnConflictUpdate(
        notes,
        rows.where((r) => !keepIds.contains(r.id)),
      );
    });
  });

  Future<void> clearNotes() => delete(notes).go();

  // --- Settings --------------------------------------------------------------

  Future<String?> readSetting(String key) async {
    final row = await (select(
      settingsEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) =>
      into(settingsEntries).insertOnConflictUpdate(
        SettingRow(key: key, value: value),
      );

  Future<int> removeSetting(String key) =>
      (delete(settingsEntries)..where((t) => t.key.equals(key))).go();

  Stream<String?> watchSetting(String key) =>
      (select(settingsEntries)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);
}

/// Exposed separately so tests can build an executor without a Flutter binding.
///
/// [NativeDatabase.memory] needs no `path_provider` and no platform channels,
/// which is exactly what makes the Drift layer unit-testable.
QueryExecutor inMemoryExecutor() => NativeDatabase.memory();

/// Overridden in tests with `AppDatabase.memory()`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
