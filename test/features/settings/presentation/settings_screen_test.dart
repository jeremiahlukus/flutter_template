import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/l10n/l10n_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  Future<TestHarness> openSettings(WidgetTester tester) async {
    final harness = TestHarness.create(user: testUser());
    await harness.pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('settings_button')));
    await tester.pumpAndSettle();
    return harness;
  }

  /// Scrolls [key] into view.
  ///
  /// The settings list is taller than the test viewport, and a `ListView` does
  /// not build off-screen children — so a finder for a lower section returns
  /// nothing until it has been scrolled to.
  Future<void> reveal(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('appearance', () {
    testWidgets('offers all three theme modes', (tester) async {
      await openSettings(tester);

      expect(find.byKey(const ValueKey('theme_system')), findsOne);
      expect(find.byKey(const ValueKey('theme_light')), findsOne);
      expect(find.byKey(const ValueKey('theme_dark')), findsOne);
    });

    testWidgets('defaults to matching the system', (tester) async {
      final harness = await openSettings(tester);

      expect(harness.read(themeModeProvider), ThemeMode.system);
    });

    testWidgets('choosing dark persists the choice', (tester) async {
      final harness = await openSettings(tester);

      await tester.tap(find.byKey(const ValueKey('theme_dark')));
      await tester.pumpAndSettle();

      expect(harness.read(themeModeProvider), ThemeMode.dark);
      expect(
        await harness.database.readSetting(SettingKeys.themeMode),
        'dark',
      );
    });

    testWidgets('choosing light persists the choice', (tester) async {
      final harness = await openSettings(tester);

      await tester.tap(find.byKey(const ValueKey('theme_light')));
      await tester.pumpAndSettle();

      expect(
        await harness.database.readSetting(SettingKeys.themeMode),
        'light',
      );
    });

    testWidgets('the choice actually changes the rendered theme', (
      tester,
    ) async {
      final harness = await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('theme_dark')));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(harness.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('a stored preference is applied on open', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(SettingKeys.themeMode, 'dark');
      await harness.pumpApp(tester);

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });
  });

  group('privacy', () {
    testWidgets('analytics is on by default', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'analytics_switch');

      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('analytics_switch')),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('toggling off persists the opt-out', (tester) async {
      final harness = await openSettings(tester);
      await reveal(tester, 'analytics_switch');

      await tester.tap(find.byKey(const ValueKey('analytics_switch')));
      await tester.pumpAndSettle();

      expect(
        await harness.database.readSetting(SettingKeys.analyticsEnabled),
        'false',
      );
    });

    testWidgets('a stored opt-out is reflected in the switch', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(
        SettingKeys.analyticsEnabled,
        'false',
      );
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await reveal(tester, 'analytics_switch');

      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('analytics_switch')),
            )
            .value,
        isFalse,
      );
    });
  });

  group('sync', () {
    testWidgets('shows zero pending with a clean cache', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'pending_sync_tile');

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pending_sync_tile')),
          matching: find.text('0'),
        ),
        findsOne,
      );
    });

    testWidgets('shows the queued count', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.upsertNote(
        testNote(id: 'q', pendingSync: true).toRow(),
      );
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await reveal(tester, 'pending_sync_tile');

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pending_sync_tile')),
          matching: find.text('1'),
        ),
        findsOne,
      );
    });

    testWidgets('sync now reports its result', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await seedRemoteNotes(harness.firestore, 'user-1', [testNote()]);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await reveal(tester, 'sync_now_tile');
      await tester.tap(find.byKey(const ValueKey('sync_now_tile')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Synced'), findsOne);
    });
  });

  group('accent colour', () {
    testWidgets('offers every brand', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'brand_picker');

      for (final brand in AppBrand.values) {
        expect(
          find.byKey(ValueKey('brand_${brand.name}')),
          findsOne,
          reason: '${brand.name} is missing from the picker',
        );
      }
    });

    testWidgets('defaults to the fallback brand', (tester) async {
      final harness = await openSettings(tester);

      expect(harness.read(brandProvider), AppBrand.fallback);
    });

    testWidgets('choosing one re-seeds the whole theme', (tester) async {
      final harness = await openSettings(tester);
      await reveal(tester, 'brand_picker');
      final before = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .colorScheme
          .primary;

      await tester.tap(find.byKey(const ValueKey('brand_teal')));
      await tester.pumpAndSettle();

      expect(harness.read(brandProvider), AppBrand.teal);
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        isNot(before),
      );
    });

    testWidgets('the choice is persisted', (tester) async {
      final harness = await openSettings(tester);
      await reveal(tester, 'brand_picker');

      await tester.tap(find.byKey(const ValueKey('brand_violet')));
      await tester.pumpAndSettle();

      expect(await harness.database.readSetting(SettingKeys.brand), 'violet');
    });

    testWidgets('a stored brand is applied on open', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(SettingKeys.brand, 'crimson');
      await harness.pumpApp(tester);

      expect(harness.read(brandProvider), AppBrand.crimson);
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        AppTheme.light(AppBrand.crimson).colorScheme.primary,
      );
    });
  });

  group('language', () {
    testWidgets('offers system plus every supported locale', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'locale_system');

      expect(find.byKey(const ValueKey('locale_system')), findsOne);
      for (final locale in AppLocales.supported) {
        expect(
          find.byKey(ValueKey('locale_${locale.languageCode}')),
          findsOne,
        );
      }
    });

    testWidgets('defaults to matching the system', (tester) async {
      final harness = await openSettings(tester);

      expect(harness.read(localeProvider), isNull);
    });

    testWidgets('choosing Spanish re-renders and persists', (tester) async {
      final harness = await openSettings(tester);
      await reveal(tester, 'locale_es');

      await tester.tap(find.byKey(const ValueKey('locale_es')));
      await tester.pumpAndSettle();

      expect(await harness.database.readSetting(SettingKeys.locale), 'es');
      expect(find.text('Ajustes'), findsOne);
    });

    testWidgets('choosing system clears the stored locale', (tester) async {
      final harness = await openSettings(tester);
      await reveal(tester, 'locale_es');
      await tester.tap(find.byKey(const ValueKey('locale_es')));
      await tester.pumpAndSettle();

      await reveal(tester, 'locale_system');
      await tester.tap(find.byKey(const ValueKey('locale_system')));
      await tester.pumpAndSettle();

      expect(await harness.database.readSetting(SettingKeys.locale), isNull);
    });
  });

  group('about', () {
    testWidgets('shows the app version', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'app_version_tile');

      expect(find.text('1.2.3 (45)'), findsOne);
    });

    testWidgets('hides the environment row in production', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'app_version_tile');

      // "prod" would just be noise to a real user.
      expect(find.byKey(const ValueKey('environment_tile')), findsNothing);
    });

    testWidgets('shows the environment row off production', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        environment: AppEnvironment.staging,
      );
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await reveal(tester, 'environment_tile');

      expect(find.text('staging'), findsOne);
    });
  });

  testWidgets('the back button returns to the notes list', (tester) async {
    await openSettings(tester);

    await tester.tap(find.byKey(const ValueKey('settings_back')));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOne);
  });
}
