import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late _MockAnalytics analytics;
  late FirebaseAnalyticsService service;

  setUp(() {
    analytics = _MockAnalytics();
    service = FirebaseAnalyticsService(analytics);
  });

  group('logEvent', () {
    test('forwards the name and parameters', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.logEvent('tapped', parameters: {'where': 'fab'});

      verify(
        () => analytics.logEvent(name: 'tapped', parameters: {'where': 'fab'}),
      ).called(1);
    });

    test('forwards a null parameter map unchanged', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.logEvent('bare');

      verify(() => analytics.logEvent(name: 'bare')).called(1);
    });
  });

  group('logScreenView', () {
    test('forwards the screen name', () async {
      when(
        () => analytics.logScreenView(screenName: any(named: 'screenName')),
      ).thenAnswer((_) async {});

      await service.logScreenView('notes');

      verify(() => analytics.logScreenView(screenName: 'notes')).called(1);
    });
  });

  group('logLogin', () {
    test('forwards the method', () async {
      when(
        () => analytics.logLogin(loginMethod: any(named: 'loginMethod')),
      ).thenAnswer((_) async {});

      await service.logLogin('password');

      verify(() => analytics.logLogin(loginMethod: 'password')).called(1);
    });
  });

  group('logSignUp', () {
    test('forwards the method', () async {
      when(
        () => analytics.logSignUp(signUpMethod: any(named: 'signUpMethod')),
      ).thenAnswer((_) async {});

      await service.logSignUp('google');

      verify(() => analytics.logSignUp(signUpMethod: 'google')).called(1);
    });
  });

  group('setUserId', () {
    test('forwards an id', () async {
      when(
        () => analytics.setUserId(id: any(named: 'id')),
      ).thenAnswer((_) async {});

      await service.setUserId('u1');

      verify(() => analytics.setUserId(id: 'u1')).called(1);
    });

    test('forwards a null id to clear it', () async {
      when(
        () => analytics.setUserId(id: any(named: 'id')),
      ).thenAnswer((_) async {});

      await service.setUserId(null);

      verify(() => analytics.setUserId()).called(1);
    });
  });

  group('failure handling', () {
    // Analytics must never be the reason a user-facing action fails. Every
    // method is checked, because a single un-guarded call is enough to crash a
    // save or a sign-in in production.
    test('logEvent swallows a throw', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenThrow(Exception('offline'));

      await expectLater(service.logEvent('x'), completes);
    });

    test('logScreenView swallows a throw', () async {
      when(
        () => analytics.logScreenView(screenName: any(named: 'screenName')),
      ).thenThrow(Exception('offline'));

      await expectLater(service.logScreenView('x'), completes);
    });

    test('logLogin swallows a throw', () async {
      when(
        () => analytics.logLogin(loginMethod: any(named: 'loginMethod')),
      ).thenThrow(Exception('offline'));

      await expectLater(service.logLogin('x'), completes);
    });

    test('logSignUp swallows a throw', () async {
      when(
        () => analytics.logSignUp(signUpMethod: any(named: 'signUpMethod')),
      ).thenThrow(Exception('offline'));

      await expectLater(service.logSignUp('x'), completes);
    });

    test('setUserId swallows a throw', () async {
      when(
        () => analytics.setUserId(id: any(named: 'id')),
      ).thenThrow(Exception('offline'));

      await expectLater(service.setUserId('x'), completes);
    });

    test('an async rejection is swallowed too', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async => throw Exception('late failure'));

      await expectLater(service.logEvent('x'), completes);
    });
  });

  test('honours the AnalyticsService contract', () {
    // Both implementations must stay interchangeable, so a fork can swap the
    // backend without touching feature code.
    expect(service, isA<AnalyticsService>());
    expect(RecordingAnalyticsService(), isA<AnalyticsService>());
  });
}
