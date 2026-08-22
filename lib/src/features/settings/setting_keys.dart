/// Keys used in the Drift `settings_entries` table.
///
/// Constants rather than inline strings: a typo in a key is a silently-ignored
/// preference, which is a miserable bug to track down.
///
/// Kept in its own file so low-level code (the locale controller, the onboarding
/// gate) can reference a key without importing the whole settings feature, which
/// would create an import cycle.
abstract final class SettingKeys {
  static const themeMode = 'theme_mode';
  static const brand = 'brand';
  static const locale = 'locale';
  static const analyticsEnabled = 'analytics_enabled';
  static const pushEnabled = 'push_enabled';
  static const onboardingCompleted = 'onboarding_completed';
  static const lastSyncedAt = 'last_synced_at';

  /// Every key, for tests that assert they are distinct.
  static const all = <String>[
    themeMode,
    brand,
    locale,
    analyticsEnabled,
    pushEnabled,
    onboardingCompleted,
    lastSyncedAt,
  ];
}
