import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_template/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TemplateApp', () {
    testWidgets('builds a router-driven MaterialApp', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routerConfig, isNotNull);
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('supplies both light and dark themes', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.brightness, Brightness.light);
      expect(app.darkTheme!.brightness, Brightness.dark);
      expect(
        app.theme!.colorScheme.primary,
        AppTheme.light().colorScheme.primary,
      );
    });

    testWidgets('renders in dark mode without error', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Notes'), findsOne);
    });
  });

  group('routing integration', () {
    testWidgets('a signed-in user lands on the notes list', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.text('Notes'), findsOne);
    });

    testWidgets('a signed-out user lands on sign-in', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.text('Notes'), findsNothing);
      expect(find.textContaining('pick up where you left off'), findsOne);
    });

    testWidgets('signing out from the profile returns to sign-in', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('profile_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sign_out_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_action')));
      await tester.pumpAndSettle();

      // The guard reacts to the auth stream, with no explicit navigation call.
      expect(find.textContaining('pick up where you left off'), findsOne);
    });

    testWidgets('navigating notes → settings → back preserves state', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.upsertNote(testNote().toRow());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_back')));
      await tester.pumpAndSettle();

      expect(find.text('First note'), findsOne);
    });

    testWidgets('every navigation is reported to analytics', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      harness.analytics.events.clear();

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();

      expect(harness.analytics.eventNames, contains('screen_view'));
    });
  });

  group('RouteErrorScreen', () {
    testWidgets('shows the error and offers a way back', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpWidget(
        tester,
        RouteErrorScreen(error: Exception('no such route')),
      );

      // Twice on purpose: the app bar title and the empty-state headline.
      expect(find.text('Page not found'), findsNWidgets(2));
      expect(find.textContaining('no such route'), findsOne);
      expect(find.text('Back to home'), findsOne);
    });

    testWidgets('falls back to generic copy with no error', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpWidget(tester, const RouteErrorScreen(error: null));

      expect(find.text('That page does not exist.'), findsOne);
    });
  });
}
