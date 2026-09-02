import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockSettings extends Mock implements NotificationSettings {}

void main() {
  group('PushPermission', () {
    test('granted and provisional can deliver', () {
      expect(PushPermission.granted.canDeliver, isTrue);
      // iOS provisional is quiet, not denied — messages still arrive.
      expect(PushPermission.provisional.canDeliver, isTrue);
    });

    test('denied and undetermined cannot deliver', () {
      expect(PushPermission.denied.canDeliver, isFalse);
      expect(PushPermission.notDetermined.canDeliver, isFalse);
    });

    test('only an undetermined state is worth prompting', () {
      // A hard denial is final until the user changes system settings, so
      // re-prompting is both useless and annoying.
      expect(PushPermission.notDetermined.canPrompt, isTrue);
      expect(PushPermission.denied.canPrompt, isFalse);
      expect(PushPermission.granted.canPrompt, isFalse);
      expect(PushPermission.provisional.canPrompt, isFalse);
    });
  });

  group('FirebasePushService permission mapping', () {
    // 0020-R16. Exercised through `currentPermission()` because the mapper is
    // private; mocking the two SDK types is cheaper than making it visible.
    Future<PushPermission> map(AuthorizationStatus status) {
      final settings = _MockSettings();
      when(() => settings.authorizationStatus).thenReturn(status);
      final messaging = _MockMessaging();
      when(messaging.getNotificationSettings).thenAnswer((_) async => settings);
      return FirebasePushService(messaging).currentPermission();
    }

    test('every platform status maps to one of ours', () async {
      // The real assertion is *totality*. `firebase_messaging` 16.6.0 added
      // `deniedPermanently`, and the switch having no wildcard is what turned
      // that into a failed build rather than a silent mis-mapping. This loop
      // fails the same way if a future version adds another value — before
      // anyone has to notice the analyzer output.
      for (final status in AuthorizationStatus.values) {
        await expectLater(
          map(status),
          completion(isA<PushPermission>()),
          reason: '$status does not map to a PushPermission',
        );
      }
    });

    test('a permanent denial is treated exactly like a denial', () async {
      // Android 13+ only; Apple reports permanent denial as plain `denied`.
      // Collapsing them is deliberate: neither can deliver, and this app does
      // not re-prompt on either, so nothing downstream can tell them apart.
      expect(
        await map(AuthorizationStatus.deniedPermanently),
        PushPermission.denied,
      );
      expect(await map(AuthorizationStatus.denied), PushPermission.denied);
    });

    test('the other three statuses keep their own meaning', () async {
      expect(await map(AuthorizationStatus.authorized), PushPermission.granted);
      expect(
        await map(AuthorizationStatus.provisional),
        PushPermission.provisional,
      );
      expect(
        await map(AuthorizationStatus.notDetermined),
        PushPermission.notDetermined,
      );
    });
  });

  group('PushMessage', () {
    test('exposes a route from the payload', () {
      const message = PushMessage(data: {'route': '/profile'});

      expect(message.route, '/profile');
    });

    test('has no route when the payload omits one', () {
      expect(const PushMessage(data: {}).route, isNull);
    });

    test('has no route for an empty or non-string value', () {
      expect(const PushMessage(data: {'route': ''}).route, isNull);
      expect(const PushMessage(data: {'route': 42}).route, isNull);
    });

    test('toString names the id and route', () {
      const message = PushMessage(
        data: {'route': '/settings'},
        messageId: 'm1',
      );

      expect(message.toString(), contains('m1'));
      expect(message.toString(), contains('/settings'));
    });
  });

  group('FakePushService', () {
    test('starts undetermined with no token', () async {
      final service = FakePushService();
      addTearDown(service.dispose);

      expect(await service.currentPermission(), PushPermission.notDetermined);
      // No permission means no token, which is what the real SDK does too.
      expect(await service.token(), isNull);
    });

    test('a prompt grants permission and unlocks the token', () async {
      final service = FakePushService();
      addTearDown(service.dispose);

      expect(await service.requestPermission(), PushPermission.granted);
      expect(service.promptCount, 1);
      expect(await service.token(), 'fake-token');
    });

    test('a scripted denial leaves the token null', () async {
      final service = FakePushService(
        permissionAfterPrompt: PushPermission.denied,
      );
      addTearDown(service.dispose);

      expect(await service.requestPermission(), PushPermission.denied);
      expect(await service.token(), isNull);
    });

    test('emits foreground messages', () async {
      final service = FakePushService();
      addTearDown(service.dispose);
      final seen = <String?>[];
      final sub = service.onForegroundMessage().listen(
        (m) => seen.add(m.title),
      );

      service.emitForeground(const PushMessage(data: {}, title: 'Hello'));
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, ['Hello']);
    });

    test('emits opened messages', () async {
      final service = FakePushService();
      addTearDown(service.dispose);
      final seen = <String?>[];
      final sub = service.onMessageOpened().listen((m) => seen.add(m.route));

      service.emitOpened(const PushMessage(data: {'route': '/profile'}));
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, ['/profile']);
    });

    test('reports a launch message', () async {
      final service = FakePushService()
        ..launchMessage = const PushMessage(data: {'route': '/settings'});
      addTearDown(service.dispose);

      expect((await service.initialMessage())!.route, '/settings');
    });

    test('rotating the token notifies listeners', () async {
      final service = FakePushService(permission: PushPermission.granted);
      addTearDown(service.dispose);
      final seen = <String>[];
      final sub = service.onTokenRefresh().listen(seen.add);

      service.rotateToken('new-token');
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, ['new-token']);
      expect(await service.token(), 'new-token');
    });

    test('deleting the token clears it', () async {
      final service = FakePushService(permission: PushPermission.granted);
      addTearDown(service.dispose);

      await service.deleteToken();

      expect(service.deleteCount, 1);
      expect(await service.token(), isNull);
    });

    test('honours the PushService contract', () {
      final service = FakePushService();
      addTearDown(service.dispose);

      expect(service, isA<PushService>());
    });
  });
}
