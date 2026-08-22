import 'package:flutter/material.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/features/update/app_version.dart';
import 'package:flutter_template/src/features/update/update_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  /// Seeds the policy document the app reads on launch.
  Future<void> seedPolicy(
    TestHarness harness,
    Map<String, dynamic> policy,
  ) => harness.firestore.doc(UpdatePolicyLocation.path).set(policy);

  group('updatePolicyProvider', () {
    test('is empty when the document is missing', () async {
      final harness = TestHarness.create();

      // Failing open: a missing document must not look like "you are out of
      // date and cannot continue".
      final policy = await harness.container.read(updatePolicyProvider.future);
      expect(policy.minimumSupported, isNull);
      expect(policy.latest, isNull);
    });

    test('reads a seeded document', () async {
      final harness = TestHarness.create();
      await seedPolicy(harness, {
        'minimumSupported': '1.0.0',
        'latest': '9.9.9',
        'storeUrl': 'https://example.com',
      });

      final policy = await harness.container.read(updatePolicyProvider.future);

      expect(policy.minimumSupported, const AppVersion(1, 0, 0));
      expect(policy.latest, const AppVersion(9, 9, 9));
    });
  });

  group('updateRequirementProvider', () {
    Future<TestHarness> withPolicy(
      Map<String, dynamic> policy, {
      String version = '1.5.0',
    }) async {
      final harness = TestHarness.create(
        packageInfo: testPackageInfo(version: version),
      );
      await seedPolicy(harness, policy);
      await harness.container.read(packageInfoProvider.future);
      await harness.container.read(updatePolicyProvider.future);
      return harness;
    }

    test('is none with no policy', () async {
      final harness = await withPolicy(const {});

      expect(
        harness.read(updateRequirementProvider),
        UpdateRequirement.none,
      );
      expect(harness.read(updateBlocksUseProvider), isFalse);
    });

    test('is required below the floor', () async {
      final harness = await withPolicy({'minimumSupported': '2.0.0'});

      expect(
        harness.read(updateRequirementProvider),
        UpdateRequirement.required,
      );
      expect(harness.read(updateBlocksUseProvider), isTrue);
    });

    test('is optional below the latest', () async {
      final harness = await withPolicy({
        'minimumSupported': '1.0.0',
        'latest': '2.0.0',
      });

      expect(
        harness.read(updateRequirementProvider),
        UpdateRequirement.optional,
      );
      expect(harness.read(updateBlocksUseProvider), isFalse);
    });

    test('is none when up to date', () async {
      final harness = await withPolicy({'latest': '1.5.0'});

      expect(harness.read(updateRequirementProvider), UpdateRequirement.none);
    });
  });

  group('UpdateGate', () {
    testWidgets('lets the app through when nothing is required', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.text('Notes'), findsOne);
      expect(find.byKey(const ValueKey('update_required')), findsNothing);
    });

    testWidgets('replaces the app when an update is required', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await seedPolicy(harness, {
        'minimumSupported': '2.0.0',
        'storeUrl': 'https://example.com/app',
      });
      await harness.pumpApp(tester);

      // Replaced entirely, not banner-ed: a required update means this client
      // can no longer talk to the backend correctly.
      expect(find.byKey(const ValueKey('update_required')), findsOne);
      expect(find.text('Update required'), findsOne);
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('offers a store link when one is configured', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await seedPolicy(harness, {
        'minimumSupported': '2.0.0',
        'storeUrl': 'https://example.com/app',
      });
      await harness.pumpApp(tester);

      expect(find.byKey(const ValueKey('update_action')), findsOne);
    });

    testWidgets('hides the action when no store URL is configured', (
      tester,
    ) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await seedPolicy(harness, {'minimumSupported': '2.0.0'});
      await harness.pumpApp(tester);

      // A button that does nothing is worse than no button.
      expect(find.byKey(const ValueKey('update_required')), findsOne);
      expect(find.byKey(const ValueKey('update_action')), findsNothing);
    });

    testWidgets('does not gate an optional update', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await seedPolicy(harness, {'latest': '2.0.0'});
      await harness.pumpApp(tester);

      // Nagging is not the same as informing.
      expect(find.byKey(const ValueKey('update_required')), findsNothing);
      expect(find.text('Notes'), findsOne);
    });

    testWidgets('is localised', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await harness.database.writeSetting(SettingKeys.locale, 'es');
      await seedPolicy(harness, {'minimumSupported': '2.0.0'});
      await harness.pumpApp(tester);

      expect(find.text('Actualización necesaria'), findsOne);
    });
  });

  group('OptionalUpdateTile', () {
    testWidgets('appears in Settings for an optional update', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        packageInfo: testPackageInfo(version: '1.0.0'),
      );
      await seedPolicy(harness, {
        'latest': '2.0.0',
        'storeUrl': 'https://example.com/app',
      });
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('optional_update_tile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byKey(const ValueKey('optional_update_tile')), findsOne);
      expect(find.textContaining('2.0.0'), findsOne);
    });

    testWidgets('is absent when up to date', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('optional_update_tile')),
        findsNothing,
      );
    });
  });
}
