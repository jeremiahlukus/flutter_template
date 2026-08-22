import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

/// Exercises the real implementation against a mocked `connectivity_plus`.
///
/// The seeding and de-duplication here is the same shape that deadlocked the
/// auth stream, so it gets the same scrutiny.
void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;
  late PlatformConnectivityService service;

  setUp(() {
    connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => changes.stream);
    service = PlatformConnectivityService(connectivity);
  });

  tearDown(() => changes.close());

  void stubCheck(List<ConnectivityResult> results) {
    when(connectivity.checkConnectivity).thenAnswer((_) async => results);
  }

  group('currentStatus', () {
    test('reports online for a real interface', () async {
      stubCheck([ConnectivityResult.wifi]);

      expect(await service.currentStatus(), NetworkStatus.online);
    });

    test('reports offline for none', () async {
      stubCheck([ConnectivityResult.none]);

      expect(await service.currentStatus(), NetworkStatus.offline);
    });

    test('assumes online when the probe throws', () async {
      when(connectivity.checkConnectivity).thenThrow(Exception('no platform'));

      // Optimistic: let the first real request decide rather than blocking the
      // UI behind a failed capability check.
      expect(await service.currentStatus(), NetworkStatus.online);
    });
  });

  group('onStatusChanged', () {
    test('seeds the current status to a new subscriber', () async {
      stubCheck([ConnectivityResult.none]);

      final seen = <NetworkStatus>[];
      final sub = service.onStatusChanged().listen(seen.add);
      await pumpEventQueue();
      await sub.cancel();

      // Without seeding, a late subscriber waits for the next change — which is
      // how an app ends up stuck showing no network state at all.
      expect(seen, [NetworkStatus.offline]);
    });

    test('emits subsequent changes', () async {
      stubCheck([ConnectivityResult.wifi]);

      final seen = <NetworkStatus>[];
      final sub = service.onStatusChanged().listen(seen.add);
      await pumpEventQueue();

      changes.add([ConnectivityResult.none]);
      await pumpEventQueue();
      changes.add([ConnectivityResult.mobile]);
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, [
        NetworkStatus.online,
        NetworkStatus.offline,
        NetworkStatus.online,
      ]);
    });

    test('does not re-emit an unchanged status', () async {
      stubCheck([ConnectivityResult.wifi]);

      final seen = <NetworkStatus>[];
      final sub = service.onStatusChanged().listen(seen.add);
      await pumpEventQueue();

      // Switching wifi → ethernet is a platform event but not a status change,
      // and re-emitting would re-trigger every reconnect listener.
      changes
        ..add([ConnectivityResult.ethernet])
        ..add([ConnectivityResult.mobile]);
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, [NetworkStatus.online]);
    });

    test('assumes online when the initial probe throws', () async {
      when(connectivity.checkConnectivity).thenThrow(Exception('no platform'));

      final seen = <NetworkStatus>[];
      final sub = service.onStatusChanged().listen(seen.add);
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, [NetworkStatus.online]);
    });

    test('forwards a stream error', () async {
      stubCheck([ConnectivityResult.wifi]);

      final errors = <Object>[];
      final sub = service.onStatusChanged().listen(
        (_) {},
        onError: errors.add,
      );
      await pumpEventQueue();

      changes.addError(Exception('platform blew up'));
      await pumpEventQueue();
      await sub.cancel();

      expect(errors, hasLength(1));
    });

    test('closes when the platform stream closes', () async {
      stubCheck([ConnectivityResult.wifi]);

      var done = false;
      final sub = service.onStatusChanged().listen(
        (_) {},
        onDone: () => done = true,
      );
      await pumpEventQueue();

      await changes.close();
      await pumpEventQueue();
      await sub.cancel();

      expect(done, isTrue);
    });

    test('the subscription can be cancelled promptly', () async {
      stubCheck([ConnectivityResult.wifi]);

      final sub = service.onStatusChanged().listen((_) {});
      await pumpEventQueue();

      // Regression guard, matching the auth stream: an `async*` generator over a
      // never-closing stream cannot be cancelled and leaks its subscription.
      await expectLater(
        sub.cancel().timeout(const Duration(seconds: 2)),
        completes,
      );
    });

    test('each subscriber gets its own seed', () async {
      stubCheck([ConnectivityResult.none]);

      final first = <NetworkStatus>[];
      final second = <NetworkStatus>[];
      final subA = service.onStatusChanged().listen(first.add);
      await pumpEventQueue();
      final subB = service.onStatusChanged().listen(second.add);
      await pumpEventQueue();

      await subA.cancel();
      await subB.cancel();

      expect(first, [NetworkStatus.offline]);
      expect(second, [NetworkStatus.offline]);
    });
  });
}
