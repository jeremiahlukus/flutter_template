import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const titleField = ValueKey('note_title_field');
  const bodyField = ValueKey('note_body_field');
  const saveButton = ValueKey('save_note_button');

  /// Opens the editor for a brand-new note via the FAB.
  Future<TestHarness> openNewNote(WidgetTester tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('new_note_button')));
    await tester.pumpAndSettle();
    return harness;
  }

  /// Opens the editor for an existing, cached note.
  Future<TestHarness> openExisting(WidgetTester tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.database.upsertNote(testNote().toRow());
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('note_note-1')));
    await tester.pumpAndSettle();
    return harness;
  }

  group('new note', () {
    testWidgets('opens with empty fields', (tester) async {
      await openNewNote(tester);

      expect(find.text('New note'), findsOne);
      expect(
        tester.widget<TextField>(find.byKey(titleField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('hides the delete action', (tester) async {
      await openNewNote(tester);

      expect(find.byKey(const ValueKey('delete_note_button')), findsNothing);
    });

    testWidgets('saving an empty note is refused with an explanation', (
      tester,
    ) async {
      final harness = await openNewNote(tester);

      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing to save'), findsOne);
      expect(await harness.database.allNotes(), isEmpty);
    });

    testWidgets('a whitespace-only note is also refused', (tester) async {
      final harness = await openNewNote(tester);

      await tester.enterText(find.byKey(titleField), '   ');
      await tester.enterText(find.byKey(bodyField), '\n\n');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      expect(await harness.database.allNotes(), isEmpty);
    });

    testWidgets('saving persists the note and returns to the list', (
      tester,
    ) async {
      final harness = await openNewNote(tester);

      await tester.enterText(find.byKey(titleField), 'Groceries');
      await tester.enterText(find.byKey(bodyField), 'Milk\nEggs');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      final saved = await harness.database.allNotes();
      expect(saved.single.title, 'Groceries');
      expect(saved.single.body, 'Milk\nEggs');
      expect(find.text('Notes'), findsOne);
    });

    testWidgets('a title alone is enough to save', (tester) async {
      final harness = await openNewNote(tester);

      await tester.enterText(find.byKey(titleField), 'Just a title');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      expect(await harness.database.allNotes(), hasLength(1));
    });

    testWidgets('a body alone is enough to save', (tester) async {
      final harness = await openNewNote(tester);

      await tester.enterText(find.byKey(bodyField), 'Just a body');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      expect((await harness.database.allNotes()).single.body, 'Just a body');
    });

    testWidgets('the saved note also reaches Firestore', (tester) async {
      final harness = await openNewNote(tester);

      await tester.enterText(find.byKey(titleField), 'Remote');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      final remote = await readRemoteNotes(harness.firestore, 'user-1');
      expect(remote.single.title, 'Remote');
    });
  });

  group('existing note', () {
    testWidgets('seeds the fields from the note', (tester) async {
      await openExisting(tester);

      expect(find.text('Edit note'), findsOne);
      expect(
        tester.widget<TextField>(find.byKey(titleField)).controller!.text,
        'First note',
      );
      expect(
        tester.widget<TextField>(find.byKey(bodyField)).controller!.text,
        'Body text',
      );
    });

    testWidgets('shows the delete action', (tester) async {
      await openExisting(tester);

      expect(find.byKey(const ValueKey('delete_note_button')), findsOne);
    });

    testWidgets('editing and saving updates the stored note', (tester) async {
      final harness = await openExisting(tester);

      await tester.enterText(find.byKey(titleField), 'Renamed');
      await tester.tap(find.byKey(saveButton));
      await tester.pumpAndSettle();

      final stored = await harness.database.allNotes();
      expect(stored, hasLength(1));
      expect(stored.single.title, 'Renamed');
      expect(stored.single.body, 'Body text');
    });

    testWidgets('the back button returns without saving', (tester) async {
      final harness = await openExisting(tester);

      await tester.enterText(find.byKey(titleField), 'Discarded');
      await tester.tap(find.byKey(const ValueKey('editor_back')));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOne);
      expect((await harness.database.allNotes()).single.title, 'First note');
    });
  });

  group('delete', () {
    testWidgets('cancelling keeps the note', (tester) async {
      final harness = await openExisting(tester);

      await tester.tap(find.byKey(const ValueKey('delete_note_button')));
      await tester.pumpAndSettle();
      expect(find.text('Delete note?'), findsOne);

      await tester.tap(find.byKey(const ValueKey('delete_cancel')));
      await tester.pumpAndSettle();

      expect(await harness.database.allNotes(), hasLength(1));
      expect(find.text('Edit note'), findsOne);
    });

    testWidgets('confirming removes the note and returns to the list', (
      tester,
    ) async {
      final harness = await openExisting(tester);

      await tester.tap(find.byKey(const ValueKey('delete_note_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_confirm')));
      await tester.pumpAndSettle();

      expect(await harness.database.allNotes(), isEmpty);
      expect(find.byKey(const ValueKey('notes_empty_state')), findsOne);
    });

    testWidgets('the deletion also reaches Firestore', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);
      await harness.read(notesRepositoryProvider)!.save(testNote());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('note_note-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_note_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_confirm')));
      await tester.pumpAndSettle();

      expect(await readRemoteNotes(harness.firestore, 'user-1'), isEmpty);
    });
  });

  group('background updates', () {
    testWidgets('a sync does not overwrite text being typed', (tester) async {
      final harness = await openExisting(tester);
      await tester.enterText(find.byKey(titleField), 'My local edit');

      // Simulate the server sending a different version while the editor is
      // open. The user's in-progress text must survive.
      await harness.database.upsertNote(
        testNote(title: 'Server version').toRow(),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(titleField)).controller!.text,
        'My local edit',
      );
    });
  });
}
