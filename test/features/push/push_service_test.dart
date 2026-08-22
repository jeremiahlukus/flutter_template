import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
