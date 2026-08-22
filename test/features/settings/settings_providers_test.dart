import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ThemeModeController.decode', () {
    test('reads light', () {
      expect(ThemeModeController.decode('light'), ThemeMode.light);
    });

    test('reads dark', () {
      expect(ThemeModeController.decode('dark'), ThemeMode.dark);
    });

    test('reads system', () {
      expect(ThemeModeController.decode('system'), ThemeMode.system);
    });

    test('falls back to system for null', () {
      expect(ThemeModeController.decode(null), ThemeMode.system);
    });

    test('falls back to system for a corrupt value', () {
      expect(ThemeModeController.decode('chartreuse'), ThemeMode.system);
    });
  });

  group('ThemeModeController.encode', () {
    test('round-trips every mode', () {
      for (final mode in ThemeMode.values) {
        expect(
          ThemeModeController.decode(ThemeModeController.encode(mode)),
          mode,
          reason: 'encode/decode must be lossless for $mode',
        );
      }
    });
  });

  group('ThemeModeController', () {
    test('defaults to system with an empty database', () async {
      final harness = TestHarness.create();

      expect(
        await harness.container.read(themeModeControllerProvider.future),
        ThemeMode.system,
      );
    });

    test('reads a previously stored value', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(SettingKeys.themeMode, 'dark');

      expect(
        await harness.container.read(themeModeControllerProvider.future),
        ThemeMode.dark,
      );
    });

    test('set persists to the database', () async {
      final harness = TestHarness.create();
      await harness.container.read(themeModeControllerProvider.future);

      await harness.container
          .read(themeModeControllerProvider.notifier)
          .set(ThemeMode.light);

      expect(
        await harness.database.readSetting(SettingKeys.themeMode),
        'light',
      );
    });

    test('set updates the exposed state immediately', () async {
      final harness = TestHarness.create();
      await harness.container.read(themeModeControllerProvider.future);

      await harness.container
          .read(themeModeControllerProvider.notifier)
          .set(ThemeMode.dark);

      expect(harness.read(themeModeProvider), ThemeMode.dark);
    });

    test('a corrupt stored value does not throw', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(SettingKeys.themeMode, 'nonsense');

      expect(
        await harness.container.read(themeModeControllerProvider.future),
        ThemeMode.system,
      );
    });
  });

  group('themeModeProvider', () {
    test('is system while the read is still in flight', () {
      final harness = TestHarness.create();
      expect(harness.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('AnalyticsEnabledController', () {
    test('defaults to enabled', () async {
      final harness = TestHarness.create();

      expect(
        await harness.container.read(analyticsEnabledControllerProvider.future),
        isTrue,
      );
    });

    test('only an explicit "false" opts out', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(
        SettingKeys.analyticsEnabled,
        'false',
      );

      expect(
        await harness.container.read(analyticsEnabledControllerProvider.future),
        isFalse,
      );
    });

    test('an unrecognised value leaves analytics on', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(
        SettingKeys.analyticsEnabled,
        'maybe',
      );

      expect(
        await harness.container.read(analyticsEnabledControllerProvider.future),
        isTrue,
      );
    });

    test('set persists the choice', () async {
      final harness = TestHarness.create();
      await harness.container.read(analyticsEnabledControllerProvider.future);

      await harness.container
          .read(analyticsEnabledControllerProvider.notifier)
          .set(false);

      expect(
        await harness.database.readSetting(SettingKeys.analyticsEnabled),
        'false',
      );
    });

    test('the choice survives a restart', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      final first = TestHarness.create(database: db);
      await first.container.read(analyticsEnabledControllerProvider.future);
      await first.container
          .read(analyticsEnabledControllerProvider.notifier)
          .set(false);

      // A fresh container over the *same* database is what a restart looks
      // like: no in-memory provider state, but the stored preference remains.
      final restarted = TestHarness.create(database: db);

      expect(
        await restarted.container.read(
          analyticsEnabledControllerProvider.future,
        ),
        isFalse,
      );
    });
  });

  group('SettingKeys', () {
    test('keys are distinct', () {
      const keys = [
        SettingKeys.themeMode,
        SettingKeys.analyticsEnabled,
        SettingKeys.lastSyncedAt,
      ];
      expect(keys.toSet(), hasLength(keys.length));
    });
  });
}
