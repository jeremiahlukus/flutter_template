import 'package:drift/drift.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/database/tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Schema-shape tests.
///
/// These exist so an accidental change to a column — dropping a default,
/// widening a length limit, moving the primary key — fails a fast test rather
/// than surfacing as corrupt data after a migration.
void main() {
  late AppDatabase db;

  setUp(() => db = inMemoryDatabase());
  tearDown(() => db.close());

  group('Notes', () {
    test('is keyed by id alone', () {
      expect(db.notes.primaryKey.map((c) => c.name), ['id']);
    });

    test('declares the expected columns', () {
      expect(
        db.notes.$columns.map((c) => c.name).toSet(),
        {'id', 'title', 'body', 'updated_at', 'pending_sync'},
      );
    });

    test('title, body, id and updated_at are required', () {
      for (final name in ['id', 'title', 'updated_at']) {
        final column = db.notes.$columns.firstWhere((c) => c.name == name);
        expect(column.$nullable, isFalse, reason: '$name must be non-null');
      }
    });

    test('body defaults to empty so a title-only note is valid', () async {
      await db.customStatement(
        'INSERT INTO notes (id, title, updated_at) '
        "VALUES ('x', 'T', '2026-01-01T00:00:00.000Z')",
      );

      expect((await db.findNote('x'))!.body, '');
    });

    test('pending_sync defaults to false', () async {
      await db.customStatement(
        'INSERT INTO notes (id, title, updated_at) '
        "VALUES ('x', 'T', '2026-01-01T00:00:00.000Z')",
      );

      expect((await db.findNote('x'))!.pendingSync, isFalse);
    });

    test('title is capped at 200 characters', () async {
      await expectLater(
        db.upsertNote(
          NoteRow(
            id: 'long',
            title: 'x' * 201,
            body: '',
            updatedAt: DateTime.utc(2026),
            pendingSync: false,
          ),
        ),
        throwsA(anything),
      );
    });

    test('a 200-character title is accepted', () async {
      await db.upsertNote(
        NoteRow(
          id: 'edge',
          title: 'x' * 200,
          body: '',
          updatedAt: DateTime.utc(2026),
          pendingSync: false,
        ),
      );

      expect((await db.findNote('edge'))!.title, hasLength(200));
    });

    test('the data class is named NoteRow', () {
      expect(db.notes.aliasedName, 'notes');
      expect(
        NoteRow(
          id: 'a',
          title: 'b',
          body: 'c',
          updatedAt: DateTime.utc(2026),
          pendingSync: false,
        ),
        isA<NoteRow>(),
      );
    });
  });

  group('SettingsEntries', () {
    test('is keyed by key alone', () {
      expect(db.settingsEntries.primaryKey.map((c) => c.name), ['key']);
    });

    test('declares only a key and a value', () {
      expect(
        db.settingsEntries.$columns.map((c) => c.name).toSet(),
        {'key', 'value'},
      );
    });

    test('both columns are required', () {
      for (final column in db.settingsEntries.$columns) {
        expect(column.$nullable, isFalse, reason: column.name);
      }
    });

    test('the data class is SettingRow', () {
      expect(
        const SettingRow(key: 'k', value: 'v'),
        isA<SettingRow>(),
      );
    });
  });

  group('database wiring', () {
    test('exposes every declared table', () {
      // A set equality on purpose: a table appearing that nobody meant to add is
      // exactly the drift worth failing on. **A fork is expected to extend this
      // set** — if you added a table, add it here. That is the correct response
      // to this test failing, not deleting the assertion.
      expect(db.allTables.map((t) => t.actualTableName).toSet(), {
        'notes',
        'settings_entries',
      });
    });

    test('foreign keys are enabled on open', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();

      expect(result.data.values.first, 1);
    });

    test('table getters are usable as query targets', () {
      expect(db.notes, isA<TableInfo<Notes, NoteRow>>());
      expect(
        db.settingsEntries,
        isA<TableInfo<SettingsEntries, SettingRow>>(),
      );
    });
  });
}
