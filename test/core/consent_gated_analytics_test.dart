import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The analytics opt-out, which for a long time was stored but not honoured.
/// These tests are what make the Settings switch mean something.
void main() {
  late RecordingAnalyticsService inner;
  var enabled = true;
  late ConsentGatedAnalyticsService gated;

  setUp(() {
    inner = RecordingAnalyticsService();
    enabled = true;
    gated = ConsentGatedAnalyticsService(
      delegate: inner,
      isEnabled: () => enabled,
    );
  });

  group('while consent is given', () {
    test('forwards events', () async {
      await gated.logEvent('tapped', parameters: {'where': 'fab'});

      expect(inner.events.single.name, 'tapped');
      expect(inner.events.single.parameters, {'where': 'fab'});
    });

    test('forwards screen views, logins, and sign-ups', () async {
      await gated.logScreenView('notes');
      await gated.logLogin('password');
      await gated.logSignUp('password');

      expect(inner.eventNames, ['screen_view', 'login', 'sign_up']);
    });

    test('forwards the user id', () async {
      await gated.setUserId('u1');
      expect(inner.userId, 'u1');
    });
  });

  group('while consent is withheld', () {
    setUp(() => enabled = false);

    test('drops events', () async {
      await gated.logEvent('tapped');
      expect(inner.events, isEmpty);
    });

    test('drops screen views', () async {
      await gated.logScreenView('notes');
      expect(inner.events, isEmpty);
    });

    test('drops logins and sign-ups', () async {
      await gated.logLogin('password');
      await gated.logSignUp('password');
      expect(inner.events, isEmpty);
    });

    test('clears the user id rather than suppressing the call', () async {
      // Suppressing this would leave the previous user attached to the
      // analytics session — the opposite of honouring the opt-out.
      await gated.setUserId('u1');

      expect(inner.userId, isNull);
    });

    test('still clears a previously set id', () async {
      enabled = true;
      await gated.setUserId('u1');
      expect(inner.userId, 'u1');

      enabled = false;
      await gated.setUserId('u1');
      expect(inner.userId, isNull);
    });
  });

  test('a mid-session opt-out takes effect on the very next event', () async {
    await gated.logEvent('before');
    enabled = false;
    await gated.logEvent('after');

    // The check is a callback, not a captured bool, precisely so this works.
    expect(inner.eventNames, ['before']);
  });

  test('a mid-session opt-in resumes collection', () async {
    enabled = false;
    await gated.logEvent('dropped');
    enabled = true;
    await gated.logEvent('kept');

    expect(inner.eventNames, ['kept']);
  });

  group('NoopAnalyticsService', () {
    test('discards everything without throwing', () async {
      final noop = NoopAnalyticsService();

      await expectLater(noop.logEvent('x'), completes);
      await expectLater(noop.logScreenView('x'), completes);
      await expectLater(noop.logLogin('x'), completes);
      await expectLater(noop.logSignUp('x'), completes);
      await expectLater(noop.setUserId('x'), completes);
    });

    test('honours the AnalyticsService contract', () {
      expect(NoopAnalyticsService(), isA<AnalyticsService>());
    });
  });
}
