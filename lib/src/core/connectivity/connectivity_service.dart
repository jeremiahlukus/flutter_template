import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a usable network path.
enum NetworkStatus {
  online,
  offline;

  bool get isOnline => this == NetworkStatus.online;

  bool get isOffline => this == NetworkStatus.offline;
}

/// Network reachability, reduced to the one bit the app actually needs.
///
/// `connectivity_plus` reports a *list* of interfaces and says nothing about
/// whether the internet is reachable through them. Collapsing that to
/// [NetworkStatus] in one place keeps the "is this online?" judgement — and its
/// caveats — from being re-litigated at every call site.
abstract interface class ConnectivityService {
  /// Emits the current status immediately, then on every change.
  Stream<NetworkStatus> onStatusChanged();

  Future<NetworkStatus> currentStatus();
}

class PlatformConnectivityService implements ConnectivityService {
  const PlatformConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// A connection over any interface counts as online; `none` is the only
  /// unambiguous signal `connectivity_plus` gives us.
  ///
  /// This deliberately does not attempt a reachability probe. A captive portal
  /// still reports a connection, so "online" here means "worth trying", not
  /// "guaranteed to succeed" — which is exactly what the sync layer needs, since
  /// it already handles a failed request by re-queueing.
  @visibleForTesting
  static NetworkStatus classify(List<ConnectivityResult> results) {
    final hasPath = results.any((r) => r != ConnectivityResult.none);
    return hasPath ? NetworkStatus.online : NetworkStatus.offline;
  }

  @override
  Stream<NetworkStatus> onStatusChanged() {
    // `Stream.multi` rather than an `async*` generator: a generator suspended in
    // `await for` over a never-closing stream cannot be cancelled.
    return Stream<NetworkStatus>.multi((controller) {
      NetworkStatus? previous;

      void emit(NetworkStatus status) {
        if (status != previous) {
          previous = status;
          controller.add(status);
        }
      }

      final subscription = _connectivity.onConnectivityChanged.listen(
        (results) => emit(classify(results)),
        onError: controller.addError,
        onDone: controller.close,
      );

      // Seed, so a late subscriber is not left waiting for the next change.
      //
      // Routed through `currentStatus` rather than chaining `.catchError` onto
      // `checkConnectivity()`: a platform implementation that throws
      // *synchronously* escapes before `catchError` is attached, and the
      // subscriber would then receive no seed at all.
      currentStatus().then(emit);

      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<NetworkStatus> currentStatus() async {
    try {
      return classify(await _connectivity.checkConnectivity());
    } catch (_) {
      return NetworkStatus.online;
    }
  }
}

/// Controllable implementation for tests.
@visibleForTesting
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService([this._status = NetworkStatus.online]);

  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status;

  /// Pushes a new status to listeners.
  void emit(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  void goOffline() => emit(NetworkStatus.offline);

  void goOnline() => emit(NetworkStatus.online);

  @override
  Stream<NetworkStatus> onStatusChanged() => Stream<NetworkStatus>.multi((c) {
    c.add(_status);
    final sub = _controller.stream.listen(
      c.add,
      onError: c.addError,
      onDone: c.close,
    );
    c.onCancel = sub.cancel;
  });

  @override
  Future<NetworkStatus> currentStatus() async => _status;

  Future<void> dispose() => _controller.close();
}

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => PlatformConnectivityService(ref.watch(connectivityProvider)),
);

/// The app's live network status. Defaults to online while resolving, so the UI
/// does not flash an offline banner on every cold start.
final networkStatusProvider = StreamProvider<NetworkStatus>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChanged(),
);

final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(networkStatusProvider).value?.isOnline ?? true,
);
