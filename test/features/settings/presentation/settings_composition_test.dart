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
