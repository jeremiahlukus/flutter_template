import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  Future<TestHarness> signedIn() async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    harness.keepAlive(notesProvider);
    return harness;
  }

  group('notesRepositoryProvider', () {
    test('is null while signed out', () {
      final harness = TestHarness.create();
      expect(harness.read(notesRepositoryProvider), isNull);
    });

    test('is built once signed in', () async {
      final harness = await signedIn();
      expect(harness.read(notesRepositoryProvider), isA<NotesRepository>());
    });

    test('is scoped to the signed-in user', () async {
      final harness = await signedIn();
      await harness.read(notesRepositoryProvider)!.save(testNote());

      final remote = await readRemoteNotes(harness.firestore, 'user-1');
      expect(remote, hasLength(1));
    });
  });

  group('notesProvider', () {
    test('is an empty list while signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesProvider);

      expect(await harness.container.read(notesProvider.future), isEmpty);
    });

    test('is empty for a signed-in user with no notes', () async {
      final harness = await signedIn();
      expect(await harness.container.read(notesProvider.future), isEmpty);
    });

    test('emits saved notes', () async {
      final harness = await signedIn();
      await harness.read(notesRepositoryProvider)!.save(testNote());
      await pumpEventQueue();

      expect(harness.read(notesProvider).value, hasLength(1));
    });

    test('reflects a deletion', () async {
      final harness = await signedIn();
      final repo = harness.read(notesRepositoryProvider)!;
      await repo.save(testNote());
      await pumpEventQueue();

      await repo.delete('note-1');
      await pumpEventQueue();

      expect(harness.read(notesProvider).value, isEmpty);
    });
  });

  group('noteProvider', () {
    test('is null for an unknown id', () async {
      final harness = await signedIn();
      await harness.container.read(notesProvider.future);

      expect(harness.read(noteProvider('ghost')), isNull);
    });

    test('finds a loaded note by id', () async {
      final harness = await signedIn();
      await harness.read(notesRepositoryProvider)!.save(testNote());
      await pumpEventQueue();

      expect(harness.read(noteProvider('note-1'))!.title, 'First note');
    });

    test('picks the right note out of several', () async {
      final harness = await signedIn();
      final repo = harness.read(notesRepositoryProvider)!;
      await repo.save(testNote(id: 'a', title: 'Alpha'));
      await repo.save(testNote(id: 'b', title: 'Beta'));
      await pumpEventQueue();

      expect(harness.read(noteProvider('b'))!.title, 'Beta');
    });

    test('is null while the list is still loading', () {
      final harness = TestHarness.create(user: testUser());
      expect(harness.read(noteProvider('anything')), isNull);
    });
  });

  group('pendingSyncCountProvider', () {
    test('is zero with no notes', () async {
      final harness = await signedIn();
      await harness.container.read(notesProvider.future);

      expect(harness.read(pendingSyncCountProvider), 0);
    });

    test('is zero when everything synced cleanly', () async {
      final harness = await signedIn();
      await harness.read(notesRepositoryProvider)!.save(testNote());
      await pumpEventQueue();

      expect(harness.read(pendingSyncCountProvider), 0);
    });

    test('counts notes the server has not accepted', () async {
      final harness = await signedIn();
      await harness.database.upsertNote(
        testNote(id: 'q1', pendingSync: true).toRow(),
      );
      await harness.database.upsertNote(
        testNote(id: 'q2', pendingSync: true).toRow(),
      );
      await harness.database.upsertNote(testNote(id: 'ok').toRow());
      await pumpEventQueue();

      expect(harness.read(pendingSyncCountProvider), 2);
    });
  });

  group('NotesController', () {
    test('starts in a data state', () async {
      final harness = await signedIn();
      expect(harness.read(notesControllerProvider), isA<AsyncData<void>>());
    });

    test('draft returns an empty note', () async {
      final harness = await signedIn();
      final draft = harness.read(notesControllerProvider.notifier).draft();

      expect(draft.isEmpty, isTrue);
      expect(draft.id, isNotEmpty);
    });

    test('save persists the note', () async {
      final harness = await signedIn();

      final ok = await harness
          .read(notesControllerProvider.notifier)
          .save(testNote());

      expect(ok, isTrue);
      expect(await harness.database.allNotes(), hasLength(1));
    });

    test('delete removes the note', () async {
      final harness = await signedIn();
      final controller = harness.read(notesControllerProvider.notifier);
      await controller.save(testNote());

      expect(await controller.delete('note-1'), isTrue);
      expect(await harness.database.allNotes(), isEmpty);
    });

    test('sync returns a report', () async {
      final harness = await signedIn();
      await seedRemoteNotes(harness.firestore, 'user-1', [testNote()]);

      final report = await harness
          .read(notesControllerProvider.notifier)
          .sync();

      expect(report!.pulled, 1);
      expect(report.ok, isTrue);
    });

    test('save reports failure rather than throwing when signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesControllerProvider);

      // The controller's contract is "return false and expose the reason in
      // state", so screens can render an error without a try/catch.
      final ok = await harness
          .read(notesControllerProvider.notifier)
          .save(testNote());

      expect(ok, isFalse);
      final state = harness.read(notesControllerProvider);
      expect(
        (state as AsyncError<void>).error,
        isA<NotesFailure>().having((e) => e.code, 'code', 'signed-out'),
      );
    });

    test('delete reports failure when signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesControllerProvider);

      expect(
        await harness.read(notesControllerProvider.notifier).delete('x'),
        isFalse,
      );
    });

    test('sync reports failure when signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesControllerProvider);

      expect(
        await harness.read(notesControllerProvider.notifier).sync(),
        isNull,
      );
    });

    test('draft throws when signed out', () async {
      final harness = TestHarness.create()..keepAlive(notesControllerProvider);

      expect(
        () => harness.read(notesControllerProvider.notifier).draft(),
        throwsA(isA<NotesFailure>()),
      );
    });

    test('state returns to data after a successful call', () async {
      final harness = await signedIn();
      final controller = harness.read(notesControllerProvider.notifier);

      await controller.save(testNote());

      expect(harness.read(notesControllerProvider), isA<AsyncData<void>>());
    });
  });

  group('cache isolation between users', () {
    test('clearing the cache on sign-out leaves no notes behind', () async {
      final harness = await signedIn();
      final repo = harness.read(notesRepositoryProvider)!;
      await repo.save(testNote());

      await repo.clearCache();

      expect(await harness.database.allNotes(), isEmpty);
    });
  });
}
