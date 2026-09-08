import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

/// A fork must be able to add its own section without editing the template's
/// file, and to drop the back arrow on a top-level tab destination.
void main() {
  testWidgets('a fork can interleave its own sections', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.settleProviders();
    await harness.pumpWidget(
      tester,
      Scaffold(
        body: ListView(
          children: const [
            ListTile(key: ValueKey('my_section'), title: Text('My section')),
            ThemeModeSection(),
            AnalyticsSection(),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('my_section')), findsOne);
    expect(find.byKey(const ValueKey('theme_dark')), findsOne);
    expect(find.byKey(const ValueKey('analytics_switch')), findsOne);
  });

  testWidgets('every section accepts a Key a driver can target', (
    tester,
  ) async {
    // 0024-R6 was "enforced by signature" — true, but a signature is not a
    // check: a section added without `super.key` compiles fine and is
    // untargetable in a fork's own layout. So pass a key to each one and find
    // it.
    final harness = TestHarness.create(user: testUser());
    await harness.settleProviders();

    // Every section the template ships. A new one must be added here, which is
    // the point — the list is the enumeration.
    final sections = <String, Widget Function(Key)>{
      'ThemeModeSection': (key) => ThemeModeSection(key: key),
      'BrandSection': (key) => BrandSection(key: key),
      'LanguageSection': (key) => LanguageSection(key: key),
      'PushSection': (key) => PushSection(key: key),
      'AnalyticsSection': (key) => AnalyticsSection(key: key),
      'SyncSection': (key) => SyncSection(key: key),
    };

    await harness.pumpWidget(
      tester,
      Scaffold(
        body: ListView(
          children: [
            for (final entry in sections.entries)
              entry.value(ValueKey('keyed_${entry.key}')),
          ],
        ),
      ),
    );

    for (final name in sections.keys) {
      expect(
        find.byKey(ValueKey('keyed_$name')),
        findsOne,
        reason: '$name dropped the Key it was given',
      );
    }
  });

  testWidgets('the back arrow can be dropped for a tab destination', (
    tester,
  ) async {
    final harness = TestHarness.create(user: testUser());
    await harness.settleProviders();
    await harness.pumpWidget(
      tester,
      const SettingsScreen(showBackButton: false),
    );

    // No back arrow, but the content is still there — the point is that chrome
    // and content are separable.
    expect(find.byKey(const ValueKey('settings_back')), findsNothing);
    expect(find.byType(SettingsSections), findsOne);
    expect(find.byKey(const ValueKey('theme_dark')), findsOne);
  });

  testWidgets('the back arrow is present by default', (tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.settleProviders();
    await harness.pumpWidget(tester, const SettingsScreen());

    expect(find.byKey(const ValueKey('settings_back')), findsOne);
  });
}
