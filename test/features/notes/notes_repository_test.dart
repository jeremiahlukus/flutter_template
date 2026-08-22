import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

// The Firestore reference types are sealed, but standing in for them is exactly
// what a mock is for, and only one test needs it (see the pull-failure case).
// ignore_for_file: subtype_of_sealed_class

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  const userId = 'user-1';
  final fixedNow = DateTime.utc(2026, 6, 1, 12);

  late FakeFirebaseFirestore firestore;
  late AppDatabase db;
  late RecordingAnalyticsService analytics;
  late NotesRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = inMemoryDatabase();
    analytics = RecordingAnalyticsService();
    repo = NotesRepository(
      firestore: firestore,
      database: db,
      analytics: analytics,
      userId: userId,
      clock: () => fixedNow,
    );
  });

  tearDown(() => db.close());

  /// Arms Firestore so writing note [id] fails.
  ///
  /// `set` is invoked on the *document*, not the collection, so the interceptor
  /// has to be attached per-document.
  void breakRemoteWrite(String id) {
    whenCalling(Invocation.method(#set, null))
        .on(firestore.doc('users/$userId/notes/$id'))
        .thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));
  }

  group('draft', () {
    test('produces an empty note with a generated id', () {
      final draft = repo.draft();

      expect(draft.id, isNotEmpty);
      expect(draft.isEmpty, isTrue);
      expect(draft.updatedAt, fixedNow);
    });

    test('generates a distinct id each time', () {
      expect(repo.draft().id, isNot(repo.draft().id));
    });
  });

  group('save', () {
    test('writes to the local cache', () async {
      await repo.save(testNote());

      expect((await repo.localNotes()).single.id, 'note-1');
    });

    test('writes to Firestore', () async {
      await repo.save(testNote());

      final remote = await readRemoteNotes(firestore, userId);
      expect(remote.single.title, 'First note');
    });

    test('stamps updatedAt from the clock, ignoring the caller', () async {
      final saved = await repo.save(
        testNote(updatedAt: DateTime.utc(1999)),
      );

      expect(saved.updatedAt, fixedNow);
    });

    test('clears pendingSync once Firestore confirms', () async {
      final saved = await repo.save(testNote(pendingSync: true));

      expect(saved.pendingSync, isFalse);
      expect((await repo.find('note-1'))!.pendingSync, isFalse);
    });

    test('records analytics on success', () async {
      await repo.save(testNote());
      expect(analytics.eventNames, contains('note_saved'));
    });

    test('updates an existing note rather than duplicating it', () async {
      await repo.save(testNote(title: 'v1'));
      await repo.save(testNote(title: 'v2'));

      final local = await repo.localNotes();
      expect(local, hasLength(1));
      expect(local.single.title, 'v2');
    });

    group('when Firestore is unavailable', () {
      setUp(() => breakRemoteWrite('note-1'));

      test('still keeps the note locally', () async {
        await repo.save(testNote());
        expect((await repo.localNotes()).single.id, 'note-1');
      });

      test('leaves it flagged for a later sync', () async {
        final saved = await repo.save(testNote());

        expect(saved.pendingSync, isTrue);
        expect(await db.pendingNotes(), hasLength(1));
      });

      test('does not throw at the caller', () async {
        await expectLater(repo.save(testNote()), completes);
      });

      test('does not record a successful save', () async {
        await repo.save(testNote());
        expect(analytics.eventNames, isNot(contains('note_saved')));
      });
    });
  });

  group('delete', () {
    setUp(() => repo.save(testNote()));

    test('removes the note locally', () async {
      await repo.delete('note-1');
      expect(await repo.localNotes(), isEmpty);
    });

    test('removes the note remotely', () async {
      await repo.delete('note-1');
      expect(await readRemoteNotes(firestore, userId), isEmpty);
    });

    test('records analytics', () async {
      await repo.delete('note-1');
      expect(analytics.eventNames, contains('note_deleted'));
    });

    test('is a no-op for an unknown id', () async {
      await expectLater(repo.delete('ghost'), completes);
      expect(await repo.localNotes(), hasLength(1));
    });

    test('still deletes locally when the remote call fails', () async {
      whenCalling(Invocation.method(#delete, null))
          .on(firestore.doc('users/$userId/notes/note-1'))
          .thenThrow(
            FirebaseException(plugin: 'firestore', code: 'unavailable'),
          );

      await repo.delete('note-1');

      expect(
        await repo.localNotes(),
        isEmpty,
        reason: 'a resurrected note is worse than a slow tombstone',
      );
    });
  });

  group('find', () {
    test('returns null for an unknown id', () async {
      expect(await repo.find('ghost'), isNull);
    });

    test('returns the cached note', () async {
      await repo.save(testNote());
      expect((await repo.find('note-1'))!.title, 'First note');
    });
  });

  group('watchNotes', () {
    test('emits the cache contents as they change', () async {
      final seen = <int>[];
      final sub = repo.watchNotes().listen((notes) => seen.add(notes.length));
      await pumpEventQueue();

      await repo.save(testNote(id: 'a'));
      await repo.save(testNote(id: 'b'));
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, 0);
      expect(seen.last, 2);
    });
  });

  group('sync', () {
    test('pulls remote notes into the cache', () async {
      await seedRemoteNotes(firestore, userId, [
        testNote(id: 'r1'),
        testNote(id: 'r2'),
      ]);

      final report = await repo.sync();

      expect(report.pulled, 2);
      expect(report.ok, isTrue);
      expect((await repo.localNotes()).map((n) => n.id).toSet(), {'r1', 'r2'});
    });

    test('pushes pending local notes', () async {
      breakRemoteWrite('local');
      await repo.save(testNote(id: 'local'));
      expect(await readRemoteNotes(firestore, userId), isEmpty);

      // Firestore recovers; the queued write should now land.
      firestore = FakeFirebaseFirestore();
      repo = NotesRepository(
        firestore: firestore,
        database: db,
        analytics: analytics,
        userId: userId,
        clock: () => fixedNow,
      );

      final report = await repo.sync();

      expect(report.pushed, 1);
      expect((await readRemoteNotes(firestore, userId)).single.id, 'local');
    });

    test('clears the pending flag on a pushed note', () async {
      breakRemoteWrite('local');
      await repo.save(testNote(id: 'local'));

      firestore = FakeFirebaseFirestore();
      repo = NotesRepository(
        firestore: firestore,
        database: db,
        analytics: analytics,
        userId: userId,
        clock: () => fixedNow,
      );
      await repo.sync();

      expect(await db.pendingNotes(), isEmpty);
    });

    test('pushes before pulling so a new note is not clobbered', () async {
      // The note exists only locally and is queued; a pull-first implementation
      // would delete it before ever sending it.
      await db.upsertNote(testNote(id: 'fresh', pendingSync: true).toRow());
      await seedRemoteNotes(firestore, userId, [testNote(id: 'server')]);

      await repo.sync();

      final ids = (await repo.localNotes()).map((n) => n.id).toSet();
      expect(ids, containsAll(<String>['fresh', 'server']));
      expect(
        (await readRemoteNotes(firestore, userId)).map((n) => n.id),
        containsAll(<String>['fresh', 'server']),
      );
    });

    test('counts a failed push and reports not-ok', () async {
      await db.upsertNote(testNote(id: 'stuck', pendingSync: true).toRow());
      breakRemoteWrite('stuck');

      final report = await repo.sync();

      expect(report.failed, 1);
      expect(report.pushed, 0);
      expect(report.ok, isFalse);
    });

    test('a failed push leaves the note queued', () async {
      await db.upsertNote(testNote(id: 'stuck', pendingSync: true).toRow());
      breakRemoteWrite('stuck');

      await repo.sync();

      expect((await db.pendingNotes()).single.id, 'stuck');
    });

    test('reports not-ok and touches nothing when the pull fails', () async {
      await repo.save(testNote(id: 'cached'));

      // `fake_cloud_firestore` cannot intercept a *collection* `get`, so this
      // one path uses mocktail to make the read throw. Everything else in this
      // file runs against the real fake.
      final users = _MockCollection();
      final userDoc = _MockDoc();
      final notes = _MockCollection();
      final broken = _MockFirestore();
      when(() => broken.collection('users')).thenReturn(users);
      when(() => users.doc(userId)).thenReturn(userDoc);
      when(() => userDoc.collection('notes')).thenReturn(notes);
      when(notes.get).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );

      repo = NotesRepository(
        firestore: broken,
        database: db,
        analytics: analytics,
        userId: userId,
        clock: () => fixedNow,
      );

      final report = await repo.sync();

      expect(report.ok, isFalse);
      expect(report.pulled, 0);
      expect(
        (await repo.localNotes()).single.id,
        'cached',
        reason: 'a failed pull must not empty the cache',
      );
      expect(analytics.eventNames, contains('note_sync_failed'));
    });

    test('records a successful sync with counts', () async {
      await seedRemoteNotes(firestore, userId, [testNote(id: 'r1')]);
      await repo.sync();

      final event = analytics.events.firstWhere((e) => e.name == 'note_sync');
      expect(event.parameters['pulled'], 1);
      expect(event.parameters['pushed'], 0);
    });

    test('an empty remote collection clears synced local notes', () async {
      await repo.save(testNote(id: 'a'));
      await firestore.doc('users/$userId/notes/a').delete();

      final report = await repo.sync();

      expect(report.pulled, 0);
      expect(await repo.localNotes(), isEmpty);
    });

    test('is idempotent', () async {
      await seedRemoteNotes(firestore, userId, [testNote(id: 'r1')]);

      await repo.sync();
      final second = await repo.sync();

      expect(second.pulled, 1);
      expect(await repo.localNotes(), hasLength(1));
    });
  });

  group('clearCache', () {
    test('empties the local cache but not Firestore', () async {
      await repo.save(testNote());

      await repo.clearCache();

      expect(await repo.localNotes(), isEmpty);
      expect(await readRemoteNotes(firestore, userId), hasLength(1));
    });
  });

  group('scoping', () {
    test('reads and writes under the signed-in user only', () async {
      await repo.save(testNote());

      final otherUser = await firestore
          .collection('users')
          .doc('someone-else')
          .collection('notes')
          .get();

      expect(otherUser.docs, isEmpty);
      expect(await readRemoteNotes(firestore, userId), hasLength(1));
    });
  });

  group('SyncReport', () {
    test('toString exposes every counter', () {
      const report = SyncReport(pushed: 1, pulled: 2, failed: 3, ok: false);
      final text = report.toString();

      expect(text, contains('1'));
      expect(text, contains('2'));
      expect(text, contains('3'));
      expect(text, contains('false'));
    });
  });

  group('NotesFailure', () {
    test('toString names the code and message', () {
      const failure = NotesFailure('c', 'm');
      expect(failure.toString(), contains('c'));
      expect(failure.toString(), contains('m'));
    });
  });
}
