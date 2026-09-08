// Push failure and payload validation.
//
// 0020-R8 previously cited "`PushRegistrar._sync` catch branch" — a branch that
// does not exist on `_sync` at all (the handling is in `_syncOnce` and
// `_remove`), and nothing a test could resolve. 0020-R12 cited `app_router.dart`
// validating against `AppRoute.paths`, which is a description of code rather
// than a test of it.
import 'package:flutter/material.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/push/push_providers.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  Future<TestHarness> signedInAndOptedIn() async {
    final harness = TestHarness.create(user: testUser());
    harness.push
      ..permission = PushPermission.granted
      ..currentToken = 'device-1';
    await harness.database.writeSetting(SettingKeys.pushEnabled, 'true');
    await harness.container.read(authStateProvider.future);
    await harness.container.read(pushEnabledControllerProvider.future);
    harness
      ..keepAlive(pushEnabledProvider)
      ..keepAlive(currentUserProvider);
    return harness;
  }

  group('a failed registration never surfaces', () {
    test('a token lookup that throws is swallowed', () async {
      final harness = await signedInAndOptedIn();
      harness.push.throwOnToken = true;

      final registrar = harness.container.read(pushRegistrarProvider);

      // The assertion is the absence of a throw. `sync()` is reached from a
      // provider listener, where an escaping error becomes an unhandled async
      // error — which the user sees, and which is what R8 forbids.
      await expectLater(registrar.sync(), completes);
      expect(
        registrar.registered,
        isEmpty,
        reason: 'Nothing should be recorded as registered after a failure',
      );
    });

    test('a later sync still succeeds once the failure clears', () async {
      // The reason a failure is safe to swallow: the next attempt retries. If a
      // failed run poisoned the registrar, swallowing would be hiding a bug.
      final harness = await signedInAndOptedIn();
      final registrar = harness.container.read(pushRegistrarProvider);

      harness.push.throwOnToken = true;
      await registrar.sync();
      expect(registrar.registered, isEmpty);

      harness.push.throwOnToken = false;
      await registrar.sync();
      expect(registrar.registered, contains('device-1'));
    });
  });

  group('an unknown route in a payload is ignored, not navigated to', () {
    testWidgets('a declared route does navigate', (tester) async {
      // The control. Without it, the negative test below passes even if push
      // navigation is broken outright.
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      expect(find.text('Notes'), findsOne);

      harness.push.emitOpened(const PushMessage(data: {'route': '/profile'}));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile_back')), findsOne);
    });

    testWidgets('an undeclared route leaves the user where they were', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      expect(find.text('Notes'), findsOne);

      harness.push.emitOpened(
        const PushMessage(data: {'route': '/not-a-real-route'}),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Notes'),
        findsOne,
        reason: 'An unknown push route must not move the user',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'An unknown route must not raise either',
      );
    });
  });
}
