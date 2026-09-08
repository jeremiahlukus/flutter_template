// The timeout budget, asserted rather than described.
//
// 0017-R11 said "10s connect, 20s send/receive" in prose. Prose does not fail
// when someone raises a timeout, so this pins both the values and the fact that
// Dio actually receives them.
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/network/api_providers.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Longest a person will stare at a spinner before deciding the app is broken.
///
/// Not a measured figure — a ceiling. The point is that a future edit cannot
/// quietly push a timeout past it.
const patience = Duration(seconds: 30);

void main() {
  group('ApiTimeouts', () {
    test('every timeout fails faster than a user gives up', () {
      for (final (name, timeout) in [
        ('connect', ApiTimeouts.connect),
        ('send', ApiTimeouts.send),
        ('receive', ApiTimeouts.receive),
      ]) {
        expect(
          timeout,
          greaterThan(Duration.zero),
          reason: '$name must be bounded; zero means wait forever',
        );
        expect(
          timeout,
          lessThanOrEqualTo(patience),
          reason: '$name is $timeout, longer than a user will wait',
        );
      }
    });

    test('connecting gives up sooner than transferring', () {
      // A connection that has not opened is dead; a transfer in progress may
      // just be slow, so it earns more time.
      expect(ApiTimeouts.connect, lessThan(ApiTimeouts.send));
      expect(ApiTimeouts.connect, lessThan(ApiTimeouts.receive));
    });

    test('the configured Dio carries every timeout', () {
      // The constants are worthless if the wiring drops one.
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.staging),
          ),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
        ],
      );
      addTearDown(container.dispose);

      final options = container.read(dioProvider).options;

      expect(options.connectTimeout, ApiTimeouts.connect);
      expect(options.sendTimeout, ApiTimeouts.send);
      expect(options.receiveTimeout, ApiTimeouts.receive);
    });
  });
}
