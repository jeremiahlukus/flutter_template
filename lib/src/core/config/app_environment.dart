import 'package:flutter/foundation.dart';

/// Which deployment this build points at.
///
/// Selected at build time with `--dart-define=APP_ENV=staging`, so it cannot be
/// changed by anything shipped to a user, and release builds can tree-shake
/// dev-only code away.
enum AppEnvironment {
  dev('dev', 'DEV'),
  staging('staging', 'STAGING'),
  prod('prod', null);

  const AppEnvironment(this.key, this.banner);

  /// Value expected in `--dart-define=APP_ENV=…`.
  final String key;

  /// Corner label shown over the UI, or null in production.
  final String? banner;

  /// The environment this binary was compiled for.
  static final AppEnvironment current = decode(
    const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
  );

  /// Unrecognised values resolve to [dev].
  ///
  /// Failing towards dev is deliberate: a typo in a CI variable should not
  /// silently produce a build that believes it is production.
  static AppEnvironment decode(String? raw) {
    for (final env in AppEnvironment.values) {
      if (env.key == raw) return env;
    }
    return AppEnvironment.dev;
  }

  bool get isProd => this == AppEnvironment.prod;

  bool get isDev => this == AppEnvironment.dev;

  /// True when debug affordances (env banner, verbose logging) should show.
  bool get showsDebugAffordances => this != AppEnvironment.prod;
}

/// Per-environment settings.
///
/// Anything that differs between deployments belongs here rather than in an
/// `if (kDebugMode)` at the point of use, so the whole matrix is readable in one
/// place and testable without rebuilding.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
    required this.verboseLogging,
    required this.syncOnReconnect,
    this.useEmulators = false,
  });

  /// The config for [environment].
  factory AppConfig.forEnvironment(
    AppEnvironment environment, {
    bool useEmulators = false,
  }) => switch (environment) {
    AppEnvironment.dev => AppConfig(
      environment: environment,
      apiBaseUrl: 'https://api.dev.example.com',
      useEmulators: useEmulators,
      // Dev traffic would pollute production analytics and crash reports.
      analyticsEnabled: false,
      crashReportingEnabled: false,
      verboseLogging: true,
      syncOnReconnect: true,
    ),
    AppEnvironment.staging => AppConfig(
      environment: environment,
      apiBaseUrl: 'https://api.staging.example.com',
      useEmulators: useEmulators,
      analyticsEnabled: true,
      crashReportingEnabled: true,
      verboseLogging: true,
      syncOnReconnect: true,
    ),
    AppEnvironment.prod => AppConfig(
      environment: environment,
      apiBaseUrl: 'https://api.example.com',
      useEmulators: useEmulators,
      analyticsEnabled: true,
      crashReportingEnabled: true,
      verboseLogging: false,
      syncOnReconnect: true,
    ),
  };

  /// The config for the environment this binary was compiled for.
  factory AppConfig.current() => AppConfig.forEnvironment(
    AppEnvironment.current,
    // Production must never be pointed at a local emulator, whatever the
    // build flag says — a release build that silently talks to localhost
    // would look like a total outage.
    useEmulators: emulatorsRequested && !AppEnvironment.current.isProd,
  );

  /// True when this build was compiled with `--dart-define=USE_EMULATORS=true`.
  ///
  /// Deliberately independent of [AppEnvironment]: you want the emulator in dev
  /// *sometimes*, and never by accident. Making it a separate opt-in means a
  /// normal `flutter run` still talks to the real dev project.
  static const emulatorsRequested = bool.fromEnvironment('USE_EMULATORS');

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool verboseLogging;
  final bool syncOnReconnect;

  /// Route Firebase traffic to the local emulator suite.
  final bool useEmulators;

  bool get isProd => environment.isProd;

  /// Corner banner text, or null in production.
  String? get banner => environment.banner;

  @override
  String toString() =>
      'AppConfig(${environment.key}${useEmulators ? ', emulators' : ''})';
}
