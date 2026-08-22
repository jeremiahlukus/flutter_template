import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// Closes the loop that `NotesRepository.save` opens: a write that failed while
/// offline stays queued, and something has to notice the network coming back.
void main() {
  Future<TestHarness> signedIn({
    NetworkStatus network = NetworkStatus.online,
    AppEnvironment environment = AppEnvironment.prod,
  }) async {
    final harness = TestHarness.create(
      user: testUser(),
      network: network,
      environment: environment,
    );
    await harness.container.read(authStateProvider.future);
    harness
      ..keepAlive(notesProvider)
      ..keepAlive(networkStatusProvider);
    return harness;
  }

  test('does not sync on the initial status emission', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    // Syncing on every cold start would hammer Firestore for no reason.
    expect(coordinator.triggeredSyncs, 0);
  });

  test('does not sync while merely staying online', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    harness.connectivity.goOnline();
    await pumpEventQueue();

    expect(coordinator.triggeredSyncs, 0);
  });

  test('does not sync on going offline', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    harness.connectivity.goOffline();
    await pumpEventQueue();

    expect(coordinator.triggeredSyncs, 0);
  });

  test('syncs on an offline to online transition', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    harness.connectivity.goOffline();
    await pumpEventQueue();
    harness.connectivity.goOnline();
    await pumpEventQueue();

    expect(coordinator.triggeredSyncs, 1);
  });

  test('pushes a queued write once the network returns', () async {
    final harness = await signedIn();
    harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    // A note the server has never seen.
    await harness.database.upsertNote(
      testNote(id: 'queued', pendingSync: true).toRow(),
    );

    harness.connectivity.goOffline();
    await pumpEventQueue();
    harness.connectivity.goOnline();
    await pumpEventQueue();

    expect(await harness.database.pendingNotes(), isEmpty);
    final remote = await readRemoteNotes(harness.firestore, 'user-1');
    expect(remote.map((n) => n.id), contains('queued'));
  });

  test('syncs again on each subsequent reconnect', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    for (var i = 0; i < 3; i++) {
      harness.connectivity.goOffline();
      await pumpEventQueue();
      harness.connectivity.goOnline();
      await pumpEventQueue();
    }

    expect(coordinator.triggeredSyncs, 3);
  });

  test('does nothing while signed out', () async {
    final harness = TestHarness.create()..keepAlive(networkStatusProvider);
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    harness.connectivity.goOffline();
    await pumpEventQueue();
    harness.connectivity.goOnline();
    await pumpEventQueue();

    // There is no per-user collection to sync against.
    expect(coordinator.triggeredSyncs, 0);
  });

  test('respects a config that disables reconnect sync', () async {
    final harness = TestHarness.create(
      user: testUser(),
      config: const AppConfig(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://example.com',
        analyticsEnabled: true,
        crashReportingEnabled: true,
        verboseLogging: false,
        syncOnReconnect: false,
      ),
    );
    await harness.container.read(authStateProvider.future);
    harness.keepAlive(networkStatusProvider);
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    harness.connectivity.goOffline();
    await pumpEventQueue();
    harness.connectivity.goOnline();
    await pumpEventQueue();

    expect(coordinator.triggeredSyncs, 0);
  });

  test('a flapping connection does not start overlapping syncs', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);
    await pumpEventQueue();

    // Two reconnects with no chance to settle in between.
    harness.connectivity.goOffline();
    harness.connectivity.goOnline();
    harness.connectivity.goOffline();
    harness.connectivity.goOnline();
    await pumpEventQueue();

    expect(coordinator.triggeredSyncs, lessThanOrEqualTo(2));
  });

  test('is disposed with the container', () async {
    final harness = await signedIn();
    final coordinator = harness.read(reconnectSyncProvider);

    expect(coordinator.dispose, returnsNormally);
  });
}
