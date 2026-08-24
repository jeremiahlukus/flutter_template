import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: databaseName));

  /// The on-disk database file name.
  ///
  /// **If you are replacing an app that is already shipped, keep its existing
  /// name here.** Renaming this points the app at a brand-new empty file beside
  /// the real one: every user's local data is still on disk with nothing
  /// referencing it, and there is no error — it presents as "the update wiped my
  /// account". Carry the old `schemaVersion` and its migrations forward too.
  ///
  /// A find-and-replace of the package name lands on this line, which is why it
  /// carries `// keep-on-rename`: `tool/rename_package.dart` reverts the rename
  /// on any line with that marker, so renaming the package cannot silently
  /// rename the database. Changing this is a decision, not a side effect.
  ///
  /// Only a test can catch a regression here, and only by asserting against the
  /// source: an in-memory database never opens a file, so the name is invisible
  /// at runtime.
  static const databaseName = 'flutter_template'; // keep-on-rename

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

/// The app's single [AppDatabase]. **Must be overridden** — `bootstrap` supplies
/// the real one, tests supply an in-memory one.
///
/// A throwing placeholder rather than a working default, matching
/// `firebase_options.dart`. The default used to construct its own instance,
/// which reads as convenient and quietly punishes any fork whose database has
/// work to do before the first frame: you build one in `bootstrap` to prime
/// settings, override *a different* provider with it by mistake, and now two
/// `AppDatabase` objects share one file. Drift only warns:
///
/// ```text
/// WARNING (drift): It looks like you've created the database class AppDatabase
/// multiple times. When these two databases use the same QueryExecutor, race
/// conditions will occur and might corrupt the database.
/// ```
///
/// Two connections mean two sets of streams, so a write through one never
/// invalidates a `watch` on the other — a corruption risk in production, and
/// hanging `pumpAndSettle` in tests. Throwing makes that impossible instead of
/// merely logged.
///
/// Tests build theirs with `inMemoryDatabase()` from `test/helpers/`,
/// deliberately not a factory here: that needs `package:drift/native.dart`,
/// which imports `dart:ffi` and breaks the web build. Nothing in `lib/` may
/// reference the native executor.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError(
    'appDatabaseProvider was read without being overridden.\n'
    'bootstrap() supplies the real database; tests supply an in-memory one via '
    'TestHarness. If you need the database before the first frame, override '
    '*this* provider — never introduce a second one for the same file.',
  ),
);
