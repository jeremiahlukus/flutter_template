import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/push/push_providers.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  /// Documents currently registered for [uid].
  Future<List<String>> registeredTokens(
    TestHarness harness,
    String uid,
  ) async {
    final snapshot = await harness.firestore
        .collection(PushTokenLocation.collection(uid))
        .get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  Future<TestHarness> signedIn({bool optedIn = true}) async {
    final harness = TestHarness.create(user: testUser());
    harness.push
      ..permission = PushPermission.granted
      ..currentToken = 'device-1';
    if (optedIn) {
      await harness.database.writeSetting(SettingKeys.pushEnabled, 'true');
    }
    await harness.container.read(authStateProvider.future);
    await harness.container.read(pushEnabledControllerProvider.future);
    harness
      ..keepAlive(pushEnabledProvider)
      ..keepAlive(currentUserProvider);
    return harness;
  }

  group('PushEnabledController', () {
    test('defaults to off', () async {
      final harness = TestHarness.create();

      // Prompting unasked is the fastest way to get permanently denied.
      expect(
        await harness.container.read(pushEnabledControllerProvider.future),
        isFalse,
      );
    });

    test('reads a stored opt-in', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(SettingKeys.pushEnabled, 'true');

      expect(
        await harness.container.read(pushEnabledControllerProvider.future),
        isTrue,
      );
    });

    test('set persists the choice', () async {
      final harness = TestHarness.create();
      await harness.container.read(pushEnabledControllerProvider.future);

      await harness.read(pushEnabledControllerProvider.notifier).set(true);

      expect(
        await harness.database.readSetting(SettingKeys.pushEnabled),
        'true',
      );
    });
  });

  group('PushRegistrar', () {
    test('registers a token for an opted-in signed-in user', () async {
      final harness = await signedIn();

      await harness.read(pushRegistrarProvider).sync();

      expect(await registeredTokens(harness, 'user-1'), ['device-1']);
    });

    test('stores the platform alongside the token', () async {
      final harness = await signedIn();
      await harness.read(pushRegistrarProvider).sync();

      final doc = await harness.firestore
          .doc(PushTokenLocation.document('user-1', 'device-1'))
          .get();

      expect(doc.data()!['token'], 'device-1');
      expect(doc.data()!['platform'], isNotEmpty);
    });

    test('registers nothing when the user has not opted in', () async {
      final harness = await signedIn(optedIn: false);

      await harness.read(pushRegistrarProvider).sync();

      // The in-app preference gates this independently of the OS permission.
      expect(await registeredTokens(harness, 'user-1'), isEmpty);
    });

    test('registers nothing while signed out', () async {
      final harness = TestHarness.create();
      harness.push.permission = PushPermission.granted;
      await harness.database.writeSetting(SettingKeys.pushEnabled, 'true');
      await harness.container.read(pushEnabledControllerProvider.future);
      harness.keepAlive(pushEnabledProvider);

      await harness.read(pushRegistrarProvider).sync();

      expect(await registeredTokens(harness, 'user-1'), isEmpty);
    });

    test('registers nothing when permission is missing', () async {
      final harness = await signedIn();
      harness.push.permission = PushPermission.denied;

      await harness.read(pushRegistrarProvider).sync();

      expect(await registeredTokens(harness, 'user-1'), isEmpty);
    });

    test('does not rewrite an unchanged token', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);

      await registrar.sync();
      await registrar.sync();

      expect(registrar.registered, ['device-1']);
    });

    test('removes the token when the user opts out', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);
      await registrar.sync();
      expect(await registeredTokens(harness, 'user-1'), ['device-1']);

      await harness.read(pushEnabledControllerProvider.notifier).set(false);
      await pumpEventQueue();
      await registrar.sync();

      expect(await registeredTokens(harness, 'user-1'), isEmpty);
    });

    test('re-registers when the token rotates', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);
      await registrar.sync();

      // Rotation after a reinstall or restore. Miss this and the device
      // silently stops receiving.
      harness.push.rotateToken('device-2');
      await pumpEventQueue();

      expect(registrar.registered, ['device-1', 'device-2']);
      expect(registrar.unregistered, contains('device-1'));
      expect(await registeredTokens(harness, 'user-1'), ['device-2']);
    });

    test('keeps other devices registered', () async {
      final harness = await signedIn();
      // A second device, registered out of band.
      await harness.firestore
          .doc(PushTokenLocation.document('user-1', 'other-device'))
          .set({'token': 'other-device'});

      await harness.read(pushRegistrarProvider).sync();

      // One document per device, so signing out here must not silence there.
      expect(
        (await registeredTokens(harness, 'user-1'))..sort(),
        ['device-1', 'other-device'],
      );
    });

    test('removes the token when the user signs out', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);
      await registrar.sync();
      expect(await registeredTokens(harness, 'user-1'), ['device-1']);

      await harness.read(authControllerProvider.notifier).signOut();
      await pumpEventQueue();
      await registrar.sync();

      // A device the user signed out of must stop receiving. The delete has to
      // use the *remembered* owner, because by the time the listener fires the
      // current user is already null.
      expect(await registeredTokens(harness, 'user-1'), isEmpty);
    });

    test('moves the token when a different user signs in', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);
      await registrar.sync();

      harness.auth.mockUser = testUser(uid: 'user-2');
      await harness.auth.signInWithCustomToken('t');
      await pumpEventQueue();
      await registrar.sync();

      // Otherwise the first account keeps receiving on a device that is now
      // signed in as someone else.
      expect(await registeredTokens(harness, 'user-1'), isEmpty);
      expect(await registeredTokens(harness, 'user-2'), ['device-1']);
    });

    test('concurrent syncs register once', () async {
      final harness = await signedIn();
      final registrar = harness.read(pushRegistrarProvider);

      // Sign-in and opt-in can land in the same frame, firing both listeners.
      await Future.wait([registrar.sync(), registrar.sync()]);

      expect(registrar.registered, ['device-1']);
    });

    test('tokens live under the signed-in user only', () {
      expect(
        PushTokenLocation.document('u1', 't1'),
        'users/u1/devices/t1',
      );
      expect(PushTokenLocation.collection('u1'), 'users/u1/devices');
    });
  });

  group('pushRouteProvider', () {
    test('emits the route from a notification tap', () async {
      final harness = TestHarness.create(user: testUser())
        ..keepAlive(pushRouteProvider);
      await pumpEventQueue();

      harness.push.emitOpened(const PushMessage(data: {'route': '/profile'}));

      expect(
        await harness.container.read(pushRouteProvider.future),
        '/profile',
      );
    });

    test('emits the route from a cold-start launch message', () async {
      final harness = TestHarness.create(user: testUser());
      harness.push.launchMessage = const PushMessage(
        data: {'route': '/settings'},
      );
      harness.keepAlive(pushRouteProvider);

      // A tap that launched a terminated app arrives here, not on the opened
      // stream — miss it and a cold-start tap goes nowhere.
      expect(
        await harness.container.read(pushRouteProvider.future),
        '/settings',
      );
    });

    test('ignores a message with no route', () async {
      final harness = TestHarness.create(user: testUser());
      final seen = <String>[];
      harness.container.listen(pushRouteProvider, (_, next) {
        final value = next.value;
        if (value != null) seen.add(value);
      }, fireImmediately: true);
      await pumpEventQueue();

      harness.push.emitOpened(const PushMessage(data: {}));
      await pumpEventQueue();

      expect(seen, isEmpty);
    });
  });

  group('settings toggle', () {
    testWidgets('is off by default', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('push_switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const ValueKey('push_switch')))
            .value,
        isFalse,
      );
    });

    testWidgets('turning it on prompts for permission', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('push_switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const ValueKey('push_switch')));
      await tester.pumpAndSettle();

      // Prompting only on an explicit opt-in, never unasked.
      expect(harness.push.promptCount, 1);
      expect(
        await harness.database.readSetting(SettingKeys.pushEnabled),
        'true',
      );
    });

    testWidgets('a denied prompt leaves the preference off', (tester) async {
      final harness = TestHarness.create(user: testUser());
      harness.push.permissionAfterPrompt = PushPermission.denied;
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('push_switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const ValueKey('push_switch')));
      await tester.pumpAndSettle();

      expect(
        await harness.database.readSetting(SettingKeys.pushEnabled),
        isNot('true'),
      );
    });

    testWidgets('is disabled and explained when blocked in system settings', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      harness.push.permission = PushPermission.denied;
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('push_switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // A live switch that cannot take effect is worse than a disabled one.
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const ValueKey('push_switch')))
            .onChanged,
        isNull,
      );
      expect(find.text('Blocked in system settings.'), findsOne);
    });
  });
}
