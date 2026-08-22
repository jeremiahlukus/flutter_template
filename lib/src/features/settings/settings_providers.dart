import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/settings/setting_keys.dart';

export 'package:flutter_template/src/features/settings/setting_keys.dart';

/// Device-local theme preference, persisted in Drift.
///
/// Reads through [AsyncNotifier] so the very first frame can resolve the stored
/// value instead of flashing the wrong brightness.
class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(
          SettingKeys.themeMode,
        );
    return decode(stored);
  }

  Future<void> set(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(SettingKeys.themeMode, encode(mode));
  }

  /// Unknown or absent values fall back to [ThemeMode.system] rather than
  /// throwing — a corrupt preference should not brick the app.
  static ThemeMode decode(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
      ThemeModeController.new,
    );

/// Synchronous view for [MaterialApp.themeMode]; [ThemeMode.system] while loading.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeModeControllerProvider).value ?? ThemeMode.system,
);

/// The seed colour the whole theme is derived from.
class BrandController extends AsyncNotifier<AppBrand> {
  @override
  Future<AppBrand> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(SettingKeys.brand);
    return AppBrand.decode(stored);
  }

  Future<void> set(AppBrand brand) async {
    state = AsyncValue.data(brand);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(SettingKeys.brand, brand.encode());
  }
}

final brandControllerProvider =
    AsyncNotifierProvider<BrandController, AppBrand>(BrandController.new);

final brandProvider = Provider<AppBrand>(
  (ref) => ref.watch(brandControllerProvider).value ?? AppBrand.fallback,
);

/// Opt-out switch for analytics collection, persisted locally.
class AnalyticsEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(
          SettingKeys.analyticsEnabled,
        );
    // Default on; only an explicit 'false' opts out.
    return stored != 'false';
  }

  Future<void> set(bool enabled) async {
    state = AsyncValue.data(enabled);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(
          SettingKeys.analyticsEnabled,
          enabled.toString(),
        );
  }
}

final analyticsEnabledControllerProvider =
    AsyncNotifierProvider<AnalyticsEnabledController, bool>(
      AnalyticsEnabledController.new,
    );

/// Synchronous view; defaults to enabled while the read is in flight.
final analyticsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(analyticsEnabledControllerProvider).value ?? true,
);
