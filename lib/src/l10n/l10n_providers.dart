import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/settings/setting_keys.dart';
import 'package:flutter_template/src/l10n/l10n.dart';

/// The user's language preference, persisted in Drift.
///
/// A null state means "match the system", which is different from "English" —
/// storing the resolved locale instead would freeze the choice the first time
/// the app ran.
class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(SettingKeys.locale);
    return decode(stored);
  }

  Future<void> set(Locale? locale) async {
    state = AsyncValue.data(locale);
    final db = ref.read(appDatabaseProvider);
    if (locale == null) {
      await db.removeSetting(SettingKeys.locale);
    } else {
      await db.writeSetting(SettingKeys.locale, locale.languageCode);
    }
  }

  /// Null for absent, empty, or unsupported values — all of which mean
  /// "follow the system" rather than an error.
  static Locale? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final locale in AppLocales.supported) {
      if (locale.languageCode == raw) return locale;
    }
    return null;
  }

  static String? encode(Locale? locale) => locale?.languageCode;
}

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Value for `MaterialApp.locale`. Null lets Flutter resolve from the platform.
final localeProvider = Provider<Locale?>(
  (ref) => ref.watch(localeControllerProvider).value,
);
