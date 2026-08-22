import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('as the signed-out landing screen', () {
    testWidgets('is what the router shows when signed out', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.byType(SignInScreen), findsOne);
    });

    testWidgets('shows the app branding', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.text('Flutter Template'), findsAtLeast(1));
      expect(find.byIcon(Icons.bolt_rounded), findsAtLeast(1));
    });

    testWidgets('renders the header without overflowing', (tester) async {
      // Regression guard: a fixed-height header overflowed the slot that
      // firebase_ui_auth hands it on a short viewport.
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('offers email sign-in', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    testWidgets('shows the sign-in subtitle copy', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.textContaining('Sign in to sync your notes'), findsOne);
    });

    testWidgets('shows the terms footer', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.textContaining('Terms of Service'), findsOne);
    });
  });

  group('direct construction', () {
    testWidgets('builds standalone against the injected auth instance', (
      tester,
    ) async {
      final harness = TestHarness.create();
      await harness.pumpWidget(tester, const TemplateSignInScreen());

      expect(find.byType(SignInScreen), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at a narrow phone width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = TestHarness.create();
      await harness.pumpWidget(tester, const TemplateSignInScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at a tablet width, using the side layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = TestHarness.create();
      await harness.pumpWidget(tester, const TemplateSignInScreen());

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.bolt_rounded), findsAtLeast(1));
    });
  });

  group('analytics handlers', () {
    // The real form cannot be driven in a test: on success `firebase_ui_auth`
    // reads `UserCredential.additionalUserInfo`, and `firebase_auth_mocks`
    // throws `UnimplementedError` from that getter. The side effects live in
    // static handlers precisely so they stay covered despite that.
    late RecordingAnalyticsService analytics;

    setUp(() => analytics = RecordingAnalyticsService());

    test('recordSignIn logs a login and sets the user id', () {
      TemplateSignInScreen.recordSignIn(analytics, 'u1');

      expect(analytics.eventNames, ['login']);
      expect(analytics.events.single.parameters, {'method': 'password'});
      expect(analytics.userId, 'u1');
    });

    test('recordSignIn tolerates a missing uid', () {
      TemplateSignInScreen.recordSignIn(analytics, null);

      expect(analytics.eventNames, ['login']);
      expect(analytics.userId, isNull);
    });

    test('recordSignUp logs a sign_up and sets the user id', () {
      TemplateSignInScreen.recordSignUp(analytics, 'u2');

      expect(analytics.eventNames, ['sign_up']);
      expect(analytics.events.single.parameters, {'method': 'password'});
      expect(analytics.userId, 'u2');
    });

    test('recordSignUp tolerates a missing uid', () {
      TemplateSignInScreen.recordSignUp(analytics, null);

      expect(analytics.userId, isNull);
    });
  });

  group('sign-in redirect', () {
    testWidgets('a signed-in user never sees this screen', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('Notes'), findsOne);
    });
  });
}
