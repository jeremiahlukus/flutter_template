import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordingAnalyticsService', () {
    late RecordingAnalyticsService analytics;

    setUp(() => analytics = RecordingAnalyticsService());

    test('starts with nothing recorded', () {
      expect(analytics.events, isEmpty);
      expect(analytics.userId, isNull);
    });

    test('logEvent records the name and parameters', () async {
      await analytics.logEvent('tapped', parameters: {'where': 'fab'});

      expect(analytics.events.single.name, 'tapped');
      expect(analytics.events.single.parameters, {'where': 'fab'});
    });

    test('logEvent defaults parameters to an empty map', () async {
      await analytics.logEvent('bare');
      expect(analytics.events.single.parameters, isEmpty);
    });

    test('logScreenView records a screen_view with the name', () async {
      await analytics.logScreenView('notes');

      expect(analytics.events.single.name, 'screen_view');
      expect(analytics.events.single.parameters, {'screen_name': 'notes'});
    });

    test('logLogin records the method', () async {
      await analytics.logLogin('password');

      expect(analytics.events.single.name, 'login');
      expect(analytics.events.single.parameters, {'method': 'password'});
    });

    test('logSignUp records the method', () async {
      await analytics.logSignUp('google');

      expect(analytics.events.single.name, 'sign_up');
      expect(analytics.events.single.parameters, {'method': 'google'});
    });

    test('setUserId stores and clears the id', () async {
      await analytics.setUserId('u1');
      expect(analytics.userId, 'u1');

      await analytics.setUserId(null);
      expect(analytics.userId, isNull);
    });

    test('preserves call order', () async {
      await analytics.logLogin('password');
      await analytics.logScreenView('home');
      await analytics.logEvent('custom');

      expect(analytics.eventNames, ['login', 'screen_view', 'custom']);
    });
  });

  group('AnalyticsEvent', () {
    test('equal name and parameters compare equal', () {
      expect(
        const AnalyticsEvent('a', {'k': 1}),
        const AnalyticsEvent('a', {'k': 1}),
      );
    });

    test('equal events hash alike', () {
      expect(
        const AnalyticsEvent('a', {'k': 1}).hashCode,
        const AnalyticsEvent('a', {'k': 1}).hashCode,
      );
    });

    test('hashing is independent of insertion order', () {
      final a = AnalyticsEvent('e', <String, Object>{'x': 1}..['y'] = 2);
      final b = AnalyticsEvent('e', <String, Object>{'y': 2}..['x'] = 1);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different name is unequal', () {
      expect(
        const AnalyticsEvent('a', {}),
        isNot(const AnalyticsEvent('b', {})),
      );
    });

    test('different parameters are unequal', () {
      expect(
        const AnalyticsEvent('a', {'k': 1}),
        isNot(const AnalyticsEvent('a', {'k': 2})),
      );
    });

    test('is not equal to an unrelated type', () {
      expect(const AnalyticsEvent('a', {}), isNot(equals('a')));
    });

    test('toString shows the name and parameters', () {
      final text = const AnalyticsEvent('a', {'k': 1}).toString();
      expect(text, contains('a'));
      expect(text, contains('k'));
    });
  });
}
