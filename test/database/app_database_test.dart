import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = inMemoryDatabase());
  tearDown(() => db.close());

  NoteRow row(
    String id, {
    String title = 'Title',
    String body = 'Body',
    int day = 1,
    bool pending = false,
  }) => NoteRow(
    id: id,
    title: title,
    body: body,
    updatedAt: DateTime.utc(2026, 1, day),
    pendingSync: pending,
  );

  group('notes', () {
    test('starts empty', () async {
      expect(await db.allNotes(), isEmpty);
    });

    test('upsert inserts then updates in place', () async {
      await db.upsertNote(row('a', title: 'One'));
      expect((await db.allNotes()).single.title, 'One');

      await db.upsertNote(row('a', title: 'Two'));
      final all = await db.allNotes();
      expect(all, hasLength(1));
      expect(all.single.title, 'Two');
    });

    test('orders newest first', () async {
      await db.upsertNote(row('old'));
      await db.upsertNote(row('new', day: 5));
      await db.upsertNote(row('mid', day: 3));

      expect(
        (await db.allNotes()).map((r) => r.id),
        ['new', 'mid', 'old'],
      );
    });

    test('findNote returns null for an unknown id', () async {
      expect(await db.findNote('nope'), isNull);
    });

    test('findNote returns the row', () async {
      await db.upsertNote(row('a'));
      expect((await db.findNote('a'))!.id, 'a');
    });

    test('deleteNote removes only the target', () async {
      await db.upsertNote(row('a'));
      await db.upsertNote(row('b'));

      expect(await db.deleteNote('a'), 1);
      expect((await db.allNotes()).single.id, 'b');
    });

    test('deleteNote on a missing id affects no rows', () async {
      expect(await db.deleteNote('ghost'), 0);
    });

    test('pendingNotes returns only unsynced rows', () async {
      await db.upsertNote(row('synced'));
      await db.upsertNote(row('dirty', pending: true));

      expect((await db.pendingNotes()).map((r) => r.id), ['dirty']);
    });

    test('watchNotes emits on every write', () async {
      final emissions = <int>[];
      final sub = db.watchNotes().listen((rows) => emissions.add(rows.length));

      await db.upsertNote(row('a'));
      await db.upsertNote(row('b'));
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.last, 2);
    });

    test('clearNotes empties the table', () async {
      await db.upsertNote(row('a'));
      await db.clearNotes();
      expect(await db.allNotes(), isEmpty);
    });
  });

  group('replaceNotes', () {
    test('swaps in the remote set', () async {
      await db.upsertNote(row('stale'));
      await db.replaceNotes([row('fresh1'), row('fresh2')]);

      expect(
        (await db.allNotes()).map((r) => r.id).toSet(),
        {'fresh1', 'fresh2'},
      );
    });

    test('preserves unsynced local work', () async {
      await db.upsertNote(row('local', title: 'My draft', pending: true));
      await db.replaceNotes([row('remote')]);

      final all = await db.allNotes();
      expect(all.map((r) => r.id).toSet(), {'local', 'remote'});
      expect(
        all.firstWhere((r) => r.id == 'local').title,
        'My draft',
        reason: 'a pull must not clobber an edit the server has not seen',
      );
    });

    test('does not let a remote copy overwrite a pending local edit', () async {
      await db.upsertNote(row('x', title: 'local edit', pending: true));
      await db.replaceNotes([row('x', title: 'server version')]);

      expect((await db.findNote('x'))!.title, 'local edit');
    });

    test('an empty remote set still clears synced rows', () async {
      await db.upsertNote(row('synced'));
      await db.replaceNotes([]);
      expect(await db.allNotes(), isEmpty);
    });
  });

  group('settings', () {
    test('readSetting returns null when absent', () async {
      expect(await db.readSetting('missing'), isNull);
    });

    test('write then read round-trips', () async {
      await db.writeSetting('theme_mode', 'dark');
      expect(await db.readSetting('theme_mode'), 'dark');
    });

    test('writing the same key overwrites', () async {
      await db.writeSetting('k', 'v1');
      await db.writeSetting('k', 'v2');
      expect(await db.readSetting('k'), 'v2');
    });

    test('removeSetting deletes the key', () async {
      await db.writeSetting('k', 'v');
      expect(await db.removeSetting('k'), 1);
      expect(await db.readSetting('k'), isNull);
    });

    test('watchSetting emits null then the written value', () async {
      final seen = <String?>[];
      final sub = db.watchSetting('k').listen(seen.add);
      // Let the initial query settle before writing, otherwise the first
      // emission already reflects the new value and the test proves nothing.
      await pumpEventQueue();

      await db.writeSetting('k', 'hello');
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, [null, 'hello']);
    });
  });

  group('timestamp fidelity', () {
    test('preserves sub-second precision through a write and read', () async {
      final precise = DateTime.utc(2026, 7, 8, 9, 10, 11, 123);
      await db.upsertNote(
        NoteRow(
          id: 'p',
          title: 'T',
          body: 'B',
          updatedAt: precise,
          pendingSync: false,
        ),
      );

      // The default integer storage format truncates to whole seconds; this is
      // the regression guard for `storeDateTimeAsText`.
      expect((await db.findNote('p'))!.updatedAt.toUtc(), precise);
    });

    test('preserves the instant for a local DateTime', () async {
      final local = DateTime(2026, 7, 8, 9, 10, 11);
      await db.upsertNote(
        NoteRow(
          id: 'l',
          title: 'T',
          body: 'B',
          updatedAt: local,
          pendingSync: false,
        ),
      );

      expect((await db.findNote('l'))!.updatedAt.toUtc(), local.toUtc());
    });
  });

  test('schemaVersion is pinned so migrations are deliberate', () {
    expect(db.schemaVersion, 1);
  });
}
