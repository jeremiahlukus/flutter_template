import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/onboarding/onboarding_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('OnboardingController', () {
    test('is incomplete with an empty database', () async {
      final harness = TestHarness.create(onboardingCompleted: false);

      expect(
        await harness.container.read(onboardingControllerProvider.future),
        isFalse,
      );
    });

    test('reads a stored completion', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(
        SettingKeys.onboardingCompleted,
        'true',
      );

      expect(
        await harness.container.read(onboardingControllerProvider.future),
        isTrue,
      );
    });

    test('only an explicit "true" counts as complete', () async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.database.writeSetting(
        SettingKeys.onboardingCompleted,
        'maybe',
      );

      expect(
        await harness.container.read(onboardingControllerProvider.future),
        isFalse,
      );
    });

    test('complete() persists the flag', () async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.container.read(onboardingControllerProvider.future);

      await harness.read(onboardingControllerProvider.notifier).complete();

      expect(
        await harness.database.readSetting(SettingKeys.onboardingCompleted),
        'true',
      );
      expect(harness.read(onboardingCompletedProvider), isTrue);
    });

    test('reset() clears the flag', () async {
      final harness = TestHarness.create();
      await harness.container.read(onboardingControllerProvider.future);

      await harness.read(onboardingControllerProvider.notifier).reset();

      expect(
        await harness.database.readSetting(SettingKeys.onboardingCompleted),
        isNull,
      );
    });

    test('completion survives a restart', () async {
      final db = harnessDatabase();
      final first = TestHarness.create(
        database: db,
        onboardingCompleted: false,
      );
      await first.container.read(onboardingControllerProvider.future);
      await first.read(onboardingControllerProvider.notifier).complete();

      final restarted = TestHarness.create(
        database: db,
        onboardingCompleted: false,
      );

      expect(
        await restarted.container.read(onboardingControllerProvider.future),
        isTrue,
      );
    });
  });

  group('onboardingCompletedProvider', () {
    test('assumes complete while the read is in flight', () {
      final harness = TestHarness.create(onboardingCompleted: false);

      // Optimistic on purpose: a returning user must never see a flash of the
      // intro on a cold start.
      expect(harness.read(onboardingCompletedProvider), isTrue);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('is what a first-run user lands on', (tester) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      expect(find.byKey(const ValueKey('onboarding_pages')), findsOne);
      expect(find.text('Your notes, everywhere'), findsOne);
    });

    testWidgets('a returning user never sees it', (tester) async {
      final harness = TestHarness.create();
      await harness.pumpApp(tester);

      expect(find.byKey(const ValueKey('onboarding_pages')), findsNothing);
    });

    testWidgets('Next advances through the pages', (tester) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('Works offline'), findsOne);

      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('Yours alone'), findsOne);
    });

    testWidgets('the button becomes "Get started" on the last page', (
      tester,
    ) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      expect(find.text('Next'), findsOne);

      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOne);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('finishing marks it complete and moves on', (tester) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_next')));
        await tester.pumpAndSettle();
      }

      expect(
        await harness.database.readSetting(SettingKeys.onboardingCompleted),
        'true',
      );
      expect(find.byKey(const ValueKey('onboarding_pages')), findsNothing);
    });

    testWidgets('Skip completes it immediately', (tester) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(harness.read(onboardingCompletedProvider), isTrue);
      expect(find.byKey(const ValueKey('onboarding_pages')), findsNothing);
    });

    testWidgets('a signed-out user reaches sign-in after finishing', (
      tester,
    ) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in to sync'), findsOne);
    });

    testWidgets('a signed-in user reaches the notes list after finishing', (
      tester,
    ) async {
      final harness = TestHarness.create(
        user: testUser(),
        onboardingCompleted: false,
      );
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOne);
    });

    testWidgets('swiping updates the page indicator', (tester) async {
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      await tester.fling(
        find.byKey(const ValueKey('onboarding_pages')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Works offline'), findsOne);
    });
  });
}
