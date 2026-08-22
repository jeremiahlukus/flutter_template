import 'package:flutter/material.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/routing/analytics_observer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecordingAnalyticsService analytics;
  late AnalyticsNavigatorObserver observer;

  setUp(() {
    analytics = RecordingAnalyticsService();
    observer = AnalyticsNavigatorObserver(analytics);
  });

  Route<void> route(String? name) => MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );

  group('screenNameOf', () {
    test('returns the route name', () {
      expect(
        AnalyticsNavigatorObserver.screenNameOf(route('/notes')),
        '/notes',
      );
    });

    test('returns null for a null route', () {
      expect(AnalyticsNavigatorObserver.screenNameOf(null), isNull);
    });

    test('returns null for an unnamed route', () {
      expect(AnalyticsNavigatorObserver.screenNameOf(route(null)), isNull);
    });

    test('returns null for an empty name', () {
      expect(AnalyticsNavigatorObserver.screenNameOf(route('')), isNull);
    });
  });

  group('didPush', () {
    test('logs the pushed route', () {
      observer.didPush(route('/notes'), null);

      expect(analytics.events.single.name, 'screen_view');
      expect(analytics.events.single.parameters, {'screen_name': '/notes'});
    });

    test('logs nothing for an unnamed route', () {
      observer.didPush(route(null), null);
      expect(analytics.events, isEmpty);
    });
  });

  group('didPop', () {
    test('logs the route being returned to', () {
      observer.didPop(route('/notes/1'), route('/notes'));

      expect(analytics.events.single.parameters, {'screen_name': '/notes'});
    });

    test('logs nothing when popping to nothing', () {
      observer.didPop(route('/notes'), null);
      expect(analytics.events, isEmpty);
    });
  });

  group('didReplace', () {
    test('logs the new route', () {
      observer.didReplace(newRoute: route('/profile'), oldRoute: route('/'));

      expect(analytics.events.single.parameters, {'screen_name': '/profile'});
    });

    test('logs nothing without a new route', () {
      observer.didReplace(oldRoute: route('/'));
      expect(analytics.events, isEmpty);
    });
  });

  test('records a full navigation sequence in order', () {
    observer
      ..didPush(route('/'), null)
      ..didPush(route('/notes/1'), route('/'))
      ..didPop(route('/notes/1'), route('/'))
      ..didReplace(newRoute: route('/profile'), oldRoute: route('/'));

    expect(
      analytics.events.map((e) => e.parameters['screen_name']),
      ['/', '/notes/1', '/', '/profile'],
    );
  });
}
