import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_template/src/features/notes/presentation/notes_screen.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  Future<TestHarness> pumpNotes(WidgetTester tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await harness.pumpApp(tester);
    return harness;
  }

  testWidgets('shows the empty state with no notes', (tester) async {
    await pumpNotes(tester);

    expect(find.byKey(const ValueKey('notes_empty_state')), findsOne);
    expect(find.text('No notes yet'), findsOne);
  });

  testWidgets('lists saved notes newest first', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    final repo = harness.read(notesRepositoryProvider)!;
    await harness.database.upsertNote(
      testNote(
        id: 'old',
        title: 'Older',
        updatedAt: DateTime.utc(2026),
      ).toRow(),
    );
    await harness.database.upsertNote(
      testNote(
        id: 'new',
        title: 'Newer',
        updatedAt: DateTime.utc(2027),
      ).toRow(),
    );
    expect(repo, isNotNull);

    await harness.pumpApp(tester);

    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(2));
    expect(
      tester.widgetList<ListTile>(tiles).map((t) => (t.title! as Text).data),
      ['Newer', 'Older'],
    );
  });

  testWidgets('renders a fallback title for an untitled note', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await harness.database.upsertNote(testNote(title: '', body: '').toRow());

    await harness.pumpApp(tester);

    expect(find.text('Untitled note'), findsOne);
  });

  testWidgets('shows the note preview as the subtitle', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await harness.database.upsertNote(
      testNote(body: 'line one\nline two').toRow(),
    );

    await harness.pumpApp(tester);

    expect(find.text('line one'), findsOne);
    expect(find.text('line two'), findsNothing);
  });

  testWidgets('hides the pending chip when everything is synced', (
    tester,
  ) async {
    await pumpNotes(tester);

    expect(find.byKey(const ValueKey('pending_sync_chip')), findsNothing);
  });

  testWidgets('shows a pending count when writes are queued', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await harness.database.upsertNote(
      testNote(id: 'q', pendingSync: true).toRow(),
    );

    await harness.pumpApp(tester);

    expect(find.byKey(const ValueKey('pending_sync_chip')), findsOne);
    expect(find.text('1 pending'), findsOne);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOne);
  });

  testWidgets('shows the user initials in the profile button', (tester) async {
    await pumpNotes(tester);

    expect(find.text('AL'), findsOne);
  });

  testWidgets('the new-note button opens the editor', (tester) async {
    await pumpNotes(tester);

    await tester.tap(find.byKey(const ValueKey('new_note_button')));
    await tester.pumpAndSettle();

    expect(find.text('New note'), findsOne);
    expect(find.byKey(const ValueKey('note_title_field')), findsOne);
  });

  testWidgets('tapping a note opens it for editing', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await harness.database.upsertNote(testNote().toRow());
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('note_note-1')));
    await tester.pumpAndSettle();

    expect(find.text('Edit note'), findsOne);
    expect(find.text('First note'), findsOne);
  });

  testWidgets('the settings button navigates to settings', (tester) async {
    await pumpNotes(tester);

    await tester.tap(find.byKey(const ValueKey('settings_button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOne);
  });

  testWidgets('the profile button navigates to the profile', (tester) async {
    await pumpNotes(tester);

    await tester.tap(find.byKey(const ValueKey('profile_button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOne);
  });

  testWidgets('sync reports its result in a snack bar', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.container.read(authStateProvider.future);
    await seedRemoteNotes(harness.firestore, 'user-1', [testNote()]);
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('sync_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Synced'), findsOne);
    expect(find.textContaining('1 down'), findsOne);
  });

  group('failure states', () {
    testWidgets('renders an error state when the notes stream fails', (
      tester,
    ) async {
      final harness = TestHarness.create(
        user: testUser(),
        extraOverrides: [
          notesProvider.overrideWith(
            (ref) => Stream<List<Note>>.error(
              StateError('cache unavailable'),
            ),
          ),
        ],
      );

      // Pumped without `pumpApp`: that helper awaits `notesProvider.future`,
      // which would rethrow the error into the test instead of letting the
      // widget render it.
      await harness.pumpWidget(tester, const NotesScreen(), settle: false);
      await tester.pump();

      expect(find.byKey(const ValueKey('notes_error_state')), findsOne);
      expect(find.text('Could not load notes'), findsOne);
      expect(find.textContaining('cache unavailable'), findsOne);
    });

    testWidgets('shows a spinner while the notes stream is pending', (
      tester,
    ) async {
      final harness = TestHarness.create(
        user: testUser(),
        extraOverrides: [
          // A stream backed by an uncompleted Completer never emits and — unlike
          // `Future.delayed` — leaves no pending timer to trip the test binding.
          notesProvider.overrideWith(
            (ref) =>
                Stream<List<Note>>.fromFuture(Completer<List<Note>>().future),
          ),
        ],
      );
      await harness.pumpWidget(tester, const NotesScreen(), settle: false);

      expect(find.byKey(const ValueKey('notes_loading')), findsOne);
    });
  });

  group('syncMessage', () {
    // Needs real translations, so it resolves them through a pumped widget
    // rather than constructing AppLocalizations by hand.
    Future<AppLocalizations> l10nFor(WidgetTester tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocales.supported,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return l10n;
    }

    testWidgets('reports a clean sync with its counts', (tester) async {
      final l10n = await l10nFor(tester);

      expect(
        syncMessage(
          l10n,
          const SyncReport(pushed: 2, pulled: 3, failed: 0, ok: true),
        ),
        'Synced — 2 up, 3 down.',
      );
    });

    testWidgets('reports a partial failure rather than claiming success', (
      tester,
    ) async {
      final l10n = await l10nFor(tester);

      // Saying "Synced" while writes are stuck would tell the user their work
      // is safe when it is not.
      expect(
        syncMessage(
          l10n,
          const SyncReport(pushed: 0, pulled: 1, failed: 2, ok: false),
        ),
        'Synced, but 2 notes could not upload.',
      );
    });

    testWidgets('uses the singular for one stuck note', (tester) async {
      final l10n = await l10nFor(tester);

      expect(
        syncMessage(
          l10n,
          const SyncReport(pushed: 0, pulled: 0, failed: 1, ok: false),
        ),
        'Synced, but 1 note could not upload.',
      );
    });

    testWidgets('reports an outright failure', (tester) async {
      final l10n = await l10nFor(tester);

      expect(syncMessage(l10n, null), 'Sync failed. Check your connection.');
    });
  });

  testWidgets('is unreachable when signed out', (tester) async {
    final harness = TestHarness.create();
    await harness.pumpApp(tester);

    // The router guard sends a signed-out visitor to sign-in, so none of the
    // notes chrome should be on screen.
    expect(find.byKey(const ValueKey('sync_button')), findsNothing);
    expect(find.byKey(const ValueKey('new_note_button')), findsNothing);
    expect(find.byKey(const ValueKey('notes_empty_state')), findsNothing);
  });
}
