import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// Length limits, and the three layers that enforce them.
///
/// Regression guards for two real bugs: an over-long title threw
/// `InvalidDataException` straight out of `save()` (uncaught, because
/// `NotesController` only catches `NotesFailure`), and an over-long body was
/// accepted locally and then rejected by the security rules — leaving the note
/// queued forever with nothing to explain it.
void main() {
  late FakeFirebaseFirestore firestore;
  late AppDatabase db;
  late NotesRepository notes;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = AppDatabase.memory();
    // Built directly rather than through Riverpod: these are repository-level
    // tests, and the provider graph adds nothing but setup.
    notes = NotesRepository(
      firestore: firestore,
      database: db,
      analytics: RecordingAnalyticsService(),
      userId: 'user-1',
    );
  });

  tearDown(() => db.close());

  group('Note.exceededLimit', () {
    test('is null within the limits', () {
      expect(testNote().exceededLimit, isNull);
      expect(testNote().isWithinLimits, isTrue);
    });

    test('accepts a title of exactly the maximum', () {
      expect(
        testNote(title: 'x' * Note.maxTitleLength).exceededLimit,
        isNull,
      );
    });

    test('reports a title one over', () {
      expect(
        testNote(title: 'x' * (Note.maxTitleLength + 1)).exceededLimit,
        NoteLimit.title,
      );
    });

    test('accepts a body of exactly the maximum', () {
      expect(testNote(body: 'y' * Note.maxBodyLength).exceededLimit, isNull);
    });

    test('reports a body one over', () {
      expect(
        testNote(body: 'y' * (Note.maxBodyLength + 1)).exceededLimit,
        NoteLimit.body,
      );
    });

    test('reports the title first when both are over', () {
      final note = testNote(
        title: 'x' * (Note.maxTitleLength + 1),
        body: 'y' * (Note.maxBodyLength + 1),
      );

      expect(note.exceededLimit, NoteLimit.title);
    });

    test('each limit knows its own maximum', () {
      expect(NoteLimit.title.max, Note.maxTitleLength);
      expect(NoteLimit.body.max, Note.maxBodyLength);
    });

    test('the limits match what Drift and the rules enforce', () {
      // Three layers, one set of numbers. If these drift apart, a note saves
      // locally and then fails to sync with no explanation.
      expect(Note.maxTitleLength, 200);
      expect(Note.maxBodyLength, 100000);
    });
  });

  group('save', () {
    test('rejects an over-long title as a NotesFailure, not a crash', () async {
      await expectLater(
        notes.save(testNote(title: 'x' * (Note.maxTitleLength + 1))),
        throwsA(
          isA<NotesFailure>().having((e) => e.code, 'code', 'too-long'),
        ),
      );
    });

    test('rejects an over-long body', () async {
      await expectLater(
        notes.save(testNote(body: 'y' * (Note.maxBodyLength + 1))),
        throwsA(
          isA<NotesFailure>().having((e) => e.code, 'code', 'too-long'),
        ),
      );
    });

    test('writes nothing locally when a limit is exceeded', () async {
      await expectLater(
        notes.save(testNote(title: 'x' * 500)),
        throwsA(isA<NotesFailure>()),
      );

      // Checked before anything is persisted, so there is no half-saved note
      // left queued.
      expect(await db.allNotes(), isEmpty);
      expect(await readRemoteNotes(firestore, 'user-1'), isEmpty);
    });

    test('the failure names the limit and its maximum', () async {
      try {
        await notes.save(testNote(title: 'x' * 500));
        fail('expected a NotesFailure');
      } on NotesFailure catch (e) {
        expect(e.message, contains('title'));
        expect(e.message, contains('${Note.maxTitleLength}'));
      }
    });

    test('saves a note at exactly the limits', () async {
      final saved = await notes.save(
        testNote(
          title: 'x' * Note.maxTitleLength,
          body: 'y' * Note.maxBodyLength,
        ),
      );

      expect(saved.pendingSync, isFalse);
      expect(await db.allNotes(), hasLength(1));
    });
  });

  group('NotesController', () {
    test('reports a length violation as state, not a throw', () async {
      final harness = TestHarness.create(user: testUser())
        ..keepAlive(notesProvider);
      await harness.container.read(authStateProvider.future);

      final ok = await harness
          .read(notesControllerProvider.notifier)
          .save(testNote(title: 'x' * 500));

      // The whole point: `_guard` catches `NotesFailure`, and an
      // `InvalidDataException` from Drift would have escaped it.
      expect(ok, isFalse);
      expect(
        harness.read(notesControllerProvider).error,
        isA<NotesFailure>().having((e) => e.code, 'code', 'too-long'),
      );
    });
  });
}
