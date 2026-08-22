import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/storage/image_source_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  Future<TestHarness> openProfile(
    WidgetTester tester, {
    bool emailVerified = true,
    bool anonymous = false,
    String? displayName = 'Ada Lovelace',
  }) async {
    final harness = TestHarness.create(
      user: testUser(
        displayName: displayName,
        isEmailVerified: emailVerified,
        isAnonymous: anonymous,
      ),
    );
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('profile_button')));
    await tester.pumpAndSettle();
    return harness;
  }

  group('rendering', () {
    testWidgets('shows the display name and email', (tester) async {
      await openProfile(tester);

      // Twice on purpose: once in the header, once seeding the rename field.
      expect(find.text('Ada Lovelace'), findsNWidgets(2));
      expect(find.text('tester@example.com'), findsOne);
    });

    testWidgets('shows initials in the avatar', (tester) async {
      await openProfile(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profile_avatar')),
          matching: find.text('AL'),
        ),
        findsOne,
      );
    });

    testWidgets('falls back to the email when there is no name', (
      tester,
    ) async {
      await openProfile(tester, displayName: null);

      expect(find.text('tester@example.com'), findsAtLeast(1));
    });

    testWidgets('hides the unverified chip for a verified user', (
      tester,
    ) async {
      await openProfile(tester);

      expect(find.byKey(const ValueKey('unverified_chip')), findsNothing);
    });

    testWidgets('warns when the email is unverified', (tester) async {
      await openProfile(tester, emailVerified: false);

      expect(find.byKey(const ValueKey('unverified_chip')), findsOne);
      expect(find.text('Email not verified'), findsOne);
    });

    testWidgets('does not warn an anonymous user about verification', (
      tester,
    ) async {
      await openProfile(tester, emailVerified: false, anonymous: true);

      expect(find.byKey(const ValueKey('unverified_chip')), findsNothing);
    });

    testWidgets('seeds the name field with the current name', (tester) async {
      await openProfile(tester);

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('display_name_field')))
            .controller!
            .text,
        'Ada Lovelace',
      );
    });

    testWidgets('the back button returns to the notes list', (tester) async {
      await openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('profile_back')));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOne);
    });
  });

  group('rename', () {
    testWidgets('saves a new display name', (tester) async {
      final harness = await openProfile(tester);

      await tester.enterText(
        find.byKey(const ValueKey('display_name_field')),
        'Grace Hopper',
      );
      await tester.tap(find.byKey(const ValueKey('save_name_button')));
      await tester.pumpAndSettle();

      expect(harness.auth.currentUser!.displayName, 'Grace Hopper');
      expect(find.text('Name updated.'), findsOne);
    });

    testWidgets('refuses a blank name', (tester) async {
      final harness = await openProfile(tester);

      await tester.enterText(
        find.byKey(const ValueKey('display_name_field')),
        '   ',
      );
      await tester.tap(find.byKey(const ValueKey('save_name_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name first.'), findsOne);
      expect(harness.auth.currentUser!.displayName, 'Ada Lovelace');
    });
  });

  group('avatar', () {
    /// Opens the source sheet and picks the gallery.
    Future<void> pickFromGallery(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('upload_avatar_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar_from_gallery')));
      await tester.pumpAndSettle();
    }

    testWidgets('offers camera and gallery', (tester) async {
      await openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('upload_avatar_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('avatar_from_camera')), findsOne);
      expect(find.byKey(const ValueKey('avatar_from_gallery')), findsOne);
      expect(find.byKey(const ValueKey('avatar_cancel')), findsOne);
    });

    testWidgets('dismissing the sheet uploads nothing', (tester) async {
      final harness = await openProfile(tester);
      harness.imageSource.result = Uint8List.fromList([1, 2, 3]);

      await tester.tap(find.byKey(const ValueKey('upload_avatar_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar_cancel')));
      await tester.pumpAndSettle();

      expect(harness.imageSource.picked, isEmpty);
      expect(harness.storage.files, isEmpty);
    });

    testWidgets('requests the chosen source', (tester) async {
      final harness = await openProfile(tester);
      harness.imageSource.result = Uint8List.fromList([1, 2, 3]);

      await tester.tap(find.byKey(const ValueKey('upload_avatar_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar_from_camera')));
      await tester.pumpAndSettle();

      expect(harness.imageSource.picked, [ImageOrigin.camera]);
    });

    testWidgets('uploads the picked bytes to the user-scoped path', (
      tester,
    ) async {
      final harness = await openProfile(tester);
      final bytes = Uint8List.fromList([9, 8, 7]);
      harness.imageSource.result = bytes;

      await pickFromGallery(tester);

      expect(harness.storage.files['users/user-1/avatar.jpg'], bytes);
      expect(
        harness.auth.currentUser!.photoURL,
        'memory://users/user-1/avatar.jpg',
      );
      expect(find.text('Avatar uploaded.'), findsOne);
    });

    testWidgets('cancelling the picker uploads nothing and says nothing', (
      tester,
    ) async {
      final harness = await openProfile(tester);
      // Null models the user backing out of the system picker.
      harness.imageSource.result = null;

      await pickFromGallery(tester);

      expect(harness.storage.files, isEmpty);
      // Backing out is normal, so there is nothing to report.
      expect(find.text('Avatar uploaded.'), findsNothing);
      expect(find.text('Could not read that image.'), findsNothing);
    });

    testWidgets('reports an unreadable image', (tester) async {
      final harness = await openProfile(tester);
      harness.imageSource.throwOnPick = true;

      await pickFromGallery(tester);

      expect(find.text('Could not read that image.'), findsOne);
      expect(harness.storage.files, isEmpty);
    });

    testWidgets('reports a storage failure with localised copy', (
      tester,
    ) async {
      final harness = await openProfile(tester);
      harness.imageSource.result = Uint8List.fromList([1]);
      harness.storage.failWith = 'unauthorized';

      await pickFromGallery(tester);

      // The localised copy for the failure *code*, not the fake's raw message.
      expect(find.text('You do not have permission to do that.'), findsOne);
    });

    testWidgets('is localised', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(SettingKeys.locale, 'es');
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('profile_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('upload_avatar_button')));
      await tester.pumpAndSettle();

      expect(find.text('Elegir de la galería'), findsOne);
    });
  });

  group('sign out', () {
    testWidgets('cancelling stays signed in', (tester) async {
      final harness = await openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('sign_out_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOne);

      await tester.tap(find.byKey(const ValueKey('confirm_cancel')));
      await tester.pumpAndSettle();

      expect(harness.auth.currentUser, isNotNull);
    });

    testWidgets('confirming signs out and clears the local cache', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);
      await harness.read(notesRepositoryProvider)!.save(testNote());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('profile_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sign_out_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_action')));
      await tester.pumpAndSettle();

      expect(harness.auth.currentUser, isNull);
      expect(
        await harness.database.allNotes(),
        isEmpty,
        reason: 'leaving the cache would leak notes to the next user',
      );
    });
  });

  group('delete account', () {
    testWidgets('cancelling keeps the account', (tester) async {
      final harness = await openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('delete_account_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Delete account?'), findsOne);

      await tester.tap(find.byKey(const ValueKey('confirm_cancel')));
      await tester.pumpAndSettle();

      expect(harness.auth.currentUser, isNotNull);
    });

    testWidgets('confirming deletes the account', (tester) async {
      final harness = await openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('delete_account_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_action')));
      await tester.pumpAndSettle();

      expect(harness.analytics.eventNames, contains('account_deleted'));
    });
  });
}
