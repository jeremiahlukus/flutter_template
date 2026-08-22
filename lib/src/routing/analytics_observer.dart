import 'package:flutter/widgets.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';

/// Logs a `screen_view` for every push/pop.
///
/// Attached to the router rather than sprinkled through `initState`, so a new
/// screen is tracked the moment it has a route — no per-screen wiring to forget.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    _log(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    _log(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) {
    _log(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _log(Route<Object?>? route) {
    final name = screenNameOf(route);
    if (name != null) _analytics.logScreenView(name);
  }

  /// Resolves a loggable name, preferring the route's declared name over its
  /// path so analytics is not polluted with ids like `/notes/abc123`.
  @visibleForTesting
  static String? screenNameOf(Route<Object?>? route) {
    final settings = route?.settings;
    if (settings == null) return null;
    final name = settings.name;
    if (name == null || name.isEmpty) return null;
    return name;
  }
}
