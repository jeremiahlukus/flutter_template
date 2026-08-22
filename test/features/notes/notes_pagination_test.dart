import 'package:flutter/material.dart';
import 'package:flutter_template/src/core/paging/page_window.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// The notes list used to load every cached row. These tests pin the bounded
/// behaviour that replaced it.
void main() {
  /// Seeds [count] notes, newest first by index.
  Future<void> seed(AppDatabase db, int count) async {
    for (var i = 0; i < count; i++) {
      await db.upsertNote(
        testNote(
          id: 'n${i.toString().padLeft(4, '0')}',
          title: 'Note $i',
          updatedAt: DateTime.utc(2026).add(Duration(minutes: i)),
        ).toRow(),
      );
    }
  }

  group('AppDatabase.watchNotes', () {
    test('is unbounded when no limit is given', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seed(db, 40);

      expect(await db.watchNotes().first, hasLength(40));
    });

    test('respects a limit', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seed(db, 40);

      expect(await db.watchNotes(limit: 10).first, hasLength(10));
    });

    test('a limit takes the newest rows, not an arbitrary slice', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seed(db, 40);

      final page = await db.watchNotes(limit: 3).first;

      expect(page.map((r) => r.title), ['Note 39', 'Note 38', 'Note 37']);
    });

    test('a limit larger than the table returns everything', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seed(db, 5);

      expect(await db.watchNotes(limit: 100).first, hasLength(5));
    });

    test('ordering is stable for identical timestamps', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final at = DateTime.utc(2026, 5, 5);
      for (final id in ['b', 'a', 'c']) {
        await db.upsertNote(testNote(id: id, updatedAt: at).toRow());
      }

      // Ties break on id descending, so paging cannot skip or repeat a row.
      expect(
        (await db.watchNotes(limit: 3).first).map((r) => r.id),
        ['c', 'b', 'a'],
      );
    });

    test('countNotes reports the row count', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seed(db, 7);

      expect(await db.countNotes(), 7);
    });

    test('the count is zero for an empty table', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      expect(await db.countNotes(), 0);
    });
  });

  group('notesProvider window', () {
    Future<TestHarness> signedIn({int notes = 0}) async {
      final harness = TestHarness.create(user: testUser());
      await seed(harness.database, notes);
      await harness.container.read(authStateProvider.future);
      harness.keepAlive(notesProvider);
      return harness;
    }

    test('shows at most one page initially', () async {
      final harness = await signedIn(notes: 100);

      final first = await harness.container.read(notesProvider.future);
      expect(first, hasLength(defaultPageSize));
    });

    test('shows everything when there is less than a page', () async {
      final harness = await signedIn(notes: 5);

      expect(await harness.container.read(notesProvider.future), hasLength(5));
    });

    test('loadMore reveals the next page', () async {
      final harness = await signedIn(notes: 100);
      await harness.container.read(notesProvider.future);
      await pumpEventQueue();

      harness.read(notesWindowProvider.notifier).loadMore();
      await pumpEventQueue();

      expect(
        harness.read(notesProvider).value,
        hasLength(defaultPageSize * 2),
      );
    });

    test('a short result tells the list it has reached the end', () async {
      final harness = await signedIn(notes: 12);
      final loaded = await harness.container.read(notesProvider.future);

      // 12 rows for a 30-row window: no count query needed to know this is all.
      expect(
        harness.read(notesWindowProvider).hasMoreAfter(loaded.length),
        isFalse,
      );
    });

    test('a full page tells the list more may exist', () async {
      final harness = await signedIn(notes: 100);
      final loaded = await harness.container.read(notesProvider.future);

      expect(
        harness.read(notesWindowProvider).hasMoreAfter(loaded.length),
        isTrue,
      );
    });

    test('is empty and ended while signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesProvider);

      expect(await harness.container.read(notesProvider.future), isEmpty);
    });
  });

  group('notes list UI', () {
    testWidgets('renders one page, not the whole cache', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await seed(harness.database, 100);
      await harness.pumpApp(tester);

      // The newest note is on screen; the oldest is not even built.
      expect(find.text('Note 99'), findsOne);
      expect(find.text('Note 0'), findsNothing);
    });

    testWidgets('shows no trailing spinner, even with more to load', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await seed(harness.database, 100);
      await harness.pumpApp(tester);

      // SQLite satisfies a wider window within a frame, so there is never a
      // page in flight to show progress for. A parked spinner would also stop
      // `pumpAndSettle` from ever settling.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('scrolling to the bottom loads more', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await seed(harness.database, 100);
      await harness.pumpApp(tester);
      expect(harness.read(notesWindowProvider).size, defaultPageSize);

      // A controlled drag rather than a fling: a fling keeps hitting the bottom
      // as new rows arrive, which grows the window repeatedly and makes the
      // assertion about momentum rather than about paging.
      await tester.drag(
        find.byKey(const ValueKey('notes_list')),
        const Offset(0, -2000),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        harness.read(notesWindowProvider).size,
        greaterThan(defaultPageSize),
      );
    });

    testWidgets('stops growing once the whole cache is shown', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await seed(harness.database, 35);
      await harness.pumpApp(tester);

      for (var i = 0; i < 4; i++) {
        await tester.drag(
          find.byKey(const ValueKey('notes_list')),
          const Offset(0, -2000),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 35 notes, 30 per page: the window reaches 60, the query returns 35,
      // and the short result stops any further growth.
      expect(harness.read(notesWindowProvider).size, defaultPageSize * 2);
    });
  });

  group('sync paging', () {
    test('pulls a collection larger than one page', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);
      final repo = harness.read(notesRepositoryProvider)!;

      await seedRemoteNotes(harness.firestore, 'user-1', [
        for (var i = 0; i < 250; i++)
          testNote(id: 'r${i.toString().padLeft(4, '0')}'),
      ]);

      final report = await repo.sync();

      // 250 > syncPageSize (200), so this only passes if the cursor advances.
      expect(report.pulled, 250);
      expect(await harness.database.countNotes(), 250);
    });

    test(
      'pulls an exact multiple of the page size without duplicating',
      () async {
        final harness = TestHarness.create(user: testUser());
        await harness.container.read(authStateProvider.future);
        final repo = harness.read(notesRepositoryProvider)!;

        await seedRemoteNotes(harness.firestore, 'user-1', [
          for (var i = 0; i < 200; i++)
            testNote(id: 'r${i.toString().padLeft(4, '0')}'),
        ]);

        final report = await repo.sync();

        // The boundary case: a full final page must not cause an extra read that
        // re-adds the last document.
        expect(report.pulled, 200);
        expect(await harness.database.countNotes(), 200);
      },
    );

    test('an empty collection pulls nothing', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);

      final report = await harness.read(notesRepositoryProvider)!.sync();

      expect(report.pulled, 0);
      expect(report.ok, isTrue);
    });
  });
}
