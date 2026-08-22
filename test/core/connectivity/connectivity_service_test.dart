import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('NetworkStatus', () {
    test('isOnline and isOffline are opposites', () {
      expect(NetworkStatus.online.isOnline, isTrue);
      expect(NetworkStatus.online.isOffline, isFalse);
      expect(NetworkStatus.offline.isOffline, isTrue);
      expect(NetworkStatus.offline.isOnline, isFalse);
    });
  });

  group('PlatformConnectivityService.classify', () {
    test('an empty result list is offline', () {
      expect(
        PlatformConnectivityService.classify([]),
        NetworkStatus.offline,
      );
    });

    test('an explicit none is offline', () {
      expect(
        PlatformConnectivityService.classify([ConnectivityResult.none]),
        NetworkStatus.offline,
      );
    });

    test('any real interface is online', () {
      for (final result in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
        ConnectivityResult.bluetooth,
        ConnectivityResult.other,
      ]) {
        expect(
          PlatformConnectivityService.classify([result]),
          NetworkStatus.online,
          reason: '$result should count as online',
        );
      }
    });

    test('a mix of none and a real interface is online', () {
      // The platform reports every interface; one usable path is enough.
      expect(
        PlatformConnectivityService.classify(
          [ConnectivityResult.none, ConnectivityResult.wifi],
        ),
        NetworkStatus.online,
      );
    });
  });

  group('FakeConnectivityService', () {
    test('defaults to online', () async {
      final service = FakeConnectivityService();
      addTearDown(service.dispose);

      expect(await service.currentStatus(), NetworkStatus.online);
    });

    test('can start offline', () async {
      final service = FakeConnectivityService(NetworkStatus.offline);
      addTearDown(service.dispose);

      expect(await service.currentStatus(), NetworkStatus.offline);
    });

    test('seeds its current status to a new subscriber', () async {
      final service = FakeConnectivityService(NetworkStatus.offline);
      addTearDown(service.dispose);

      expect(await service.onStatusChanged().first, NetworkStatus.offline);
    });

    test('emits transitions in order', () async {
      final service = FakeConnectivityService();
      addTearDown(service.dispose);

      final seen = <NetworkStatus>[];
      final sub = service.onStatusChanged().listen(seen.add);
      await pumpEventQueue();

      service.goOffline();
      await pumpEventQueue();
      service.goOnline();
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, [
        NetworkStatus.online,
        NetworkStatus.offline,
        NetworkStatus.online,
      ]);
    });

    test('currentStatus tracks the last emission', () async {
      final service = FakeConnectivityService();
      addTearDown(service.dispose);

      service.goOffline();
      expect(await service.currentStatus(), NetworkStatus.offline);
    });

    test('the subscription can be cancelled', () async {
      final service = FakeConnectivityService();
      addTearDown(service.dispose);

      final sub = service.onStatusChanged().listen((_) {});
      await pumpEventQueue();

      await expectLater(
        sub.cancel().timeout(const Duration(seconds: 2)),
        completes,
      );
    });
  });

  group('providers', () {
    test('networkStatusProvider surfaces the service stream', () async {
      final harness = TestHarness.create(network: NetworkStatus.offline)
        ..keepAlive(networkStatusProvider);

      expect(
        await harness.container.read(networkStatusProvider.future),
        NetworkStatus.offline,
      );
    });

    test('isOnlineProvider defaults to true while resolving', () {
      final harness = TestHarness.create(network: NetworkStatus.offline);

      // Optimistic on purpose: an offline banner flashing on every cold start
      // would be worse than a frame of stale state.
      expect(harness.read(isOnlineProvider), isTrue);
    });

    test('isOnlineProvider reflects a resolved offline status', () async {
      final harness = TestHarness.create(network: NetworkStatus.offline)
        ..keepAlive(networkStatusProvider);
      await harness.container.read(networkStatusProvider.future);

      expect(harness.read(isOnlineProvider), isFalse);
    });

    test('isOnlineProvider follows a live transition', () async {
      final harness = TestHarness.create()..keepAlive(networkStatusProvider);
      await harness.container.read(networkStatusProvider.future);
      expect(harness.read(isOnlineProvider), isTrue);

      harness.connectivity.goOffline();
      await pumpEventQueue();

      expect(harness.read(isOnlineProvider), isFalse);
    });

    test('connectivityProvider builds a real Connectivity by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(connectivityProvider), isA<Connectivity>());
    });

    test('connectivityServiceProvider wraps it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(connectivityServiceProvider),
        isA<PlatformConnectivityService>(),
      );
    });
  });
}
