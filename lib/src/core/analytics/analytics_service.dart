import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';

/// Analytics seen by feature code.
///
/// Features depend on this interface rather than [FirebaseAnalytics] so that
/// tests can assert on emitted events without a Firebase binding, and so a fork
/// can swap in Amplitude/Segment by writing one new implementation.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  Future<void> logScreenView(String screenName);

  Future<void> logLogin(String method);

  Future<void> logSignUp(String method);

  Future<void> setUserId(String? id);
}

/// Production implementation backed by Firebase Analytics.
///
/// Every call is best-effort: analytics must never be the reason a user-facing
/// action fails, so failures are logged and swallowed.
class FirebaseAnalyticsService implements AnalyticsService {
  const FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> _guard(String label, Future<void> Function() body) async {
    try {
      await body();
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Analytics call "$label" failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      _guard(
        'logEvent:$name',
        () => _analytics.logEvent(name: name, parameters: parameters),
      );

  @override
  Future<void> logScreenView(String screenName) => _guard(
    'logScreenView:$screenName',
    () => _analytics.logScreenView(screenName: screenName),
  );

  @override
  Future<void> logLogin(String method) => _guard(
    'logLogin',
    () => _analytics.logLogin(loginMethod: method),
  );

  @override
  Future<void> logSignUp(String method) => _guard(
    'logSignUp',
    () => _analytics.logSignUp(signUpMethod: method),
  );

  @override
  Future<void> setUserId(String? id) => _guard(
    'setUserId',
    () => _analytics.setUserId(id: id),
  );
}

/// In-memory implementation that records calls instead of sending them.
///
/// Used by the test suite and by `--dart-define=ANALYTICS=off` local runs.
@visibleForTesting
class RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];

  String? userId;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(AnalyticsEvent(name, parameters ?? const {}));
  }

  @override
  Future<void> logScreenView(String screenName) =>
      logEvent('screen_view', parameters: {'screen_name': screenName});

  @override
  Future<void> logLogin(String method) =>
      logEvent('login', parameters: {'method': method});

  @override
  Future<void> logSignUp(String method) =>
      logEvent('sign_up', parameters: {'method': method});

  @override
  Future<void> setUserId(String? id) async => userId = id;

  /// Names of every recorded event, in order. Convenience for assertions.
  List<String> get eventNames => events.map((e) => e.name).toList();
}

@immutable
class AnalyticsEvent {
  const AnalyticsEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent &&
      other.name == name &&
      mapEquals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(
    name,
    // MapEntry has no value equality, so hashing the entries directly gives
    // two identical maps different hashes. Hashing sorted "key=value"
    // strings is both stable and independent of insertion order, matching
    // the `mapEquals` used by `==`.
    Object.hashAll(
      parameters.entries.map((e) => '${e.key}=${e.value}').toList()..sort(),
    ),
  );

  @override
  String toString() => 'AnalyticsEvent($name, $parameters)';
}

/// Drops every call while the user has opted out.
///
/// A decorator rather than an `if (enabled)` at each call site: consent is
/// checked in exactly one place, so a new feature cannot forget to honour it.
/// The check is a callback, not a captured bool, so a mid-session opt-out takes
/// effect on the very next event.
class ConsentGatedAnalyticsService implements AnalyticsService {
  const ConsentGatedAnalyticsService({
    required AnalyticsService delegate,
    required bool Function() isEnabled,
  }) : _delegate = delegate,
       _isEnabled = isEnabled;

  final AnalyticsService _delegate;
  final bool Function() _isEnabled;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_isEnabled()) return;
    await _delegate.logEvent(name, parameters: parameters);
  }

  @override
  Future<void> logScreenView(String screenName) async {
    if (!_isEnabled()) return;
    await _delegate.logScreenView(screenName);
  }

  @override
  Future<void> logLogin(String method) async {
    if (!_isEnabled()) return;
    await _delegate.logLogin(method);
  }

  @override
  Future<void> logSignUp(String method) async {
    if (!_isEnabled()) return;
    await _delegate.logSignUp(method);
  }

  /// Always forwarded, including when disabled.
  ///
  /// Clearing the id is how an opt-out is *honoured* downstream, so suppressing
  /// it would leave the previous user attached to the analytics session.
  @override
  Future<void> setUserId(String? id) async {
    if (!_isEnabled()) {
      await _delegate.setUserId(null);
      return;
    }
    await _delegate.setUserId(id);
  }
}

/// The analytics instance the app uses.
///
/// Two gates, both honoured here so no feature has to think about either:
/// the build's environment (`AppConfig.analyticsEnabled` — dev traffic must not
/// pollute production) and the user's own choice.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.analyticsEnabled) return NoopAnalyticsService();

  return ConsentGatedAnalyticsService(
    delegate: FirebaseAnalyticsService(ref.watch(firebaseAnalyticsProvider)),
    isEnabled: () => ref.read(analyticsEnabledProvider),
  );
});

/// Discards everything. Used in non-production environments.
class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> logLogin(String method) async {}

  @override
  Future<void> logSignUp(String method) async {}

  @override
  Future<void> setUserId(String? id) async {}
}
