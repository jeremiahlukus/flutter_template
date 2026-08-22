import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_template/src/features/settings/setting_keys.dart';

/// Where a device token is stored, so a server can target this install.
///
/// Keyed by token under the signed-in user, matching the `users/{uid}/…` scheme
/// the security rules already protect. One document per device, so signing out
/// on one phone does not silence the others.
abstract final class PushTokenLocation {
  static String collection(String userId) => 'users/$userId/devices';

  static String document(String userId, String token) =>
      '${collection(userId)}/$token';
}

/// The user's notification preference, persisted locally.
///
/// Separate from the OS permission: the OS answers "may we?", this answers
/// "does the user want us to?". Both must be true to register a token, and
/// conflating them means a user who turns notifications off in-app still gets
/// them until they find the system settings.
class PushEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(SettingKeys.pushEnabled);
    // Default off: asking for notification permission unprompted is the
    // fastest way to get permanently denied.
    return stored == 'true';
  }

  Future<void> set(bool enabled) async {
    state = AsyncValue.data(enabled);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(SettingKeys.pushEnabled, enabled.toString());
  }
}

final pushEnabledControllerProvider =
    AsyncNotifierProvider<PushEnabledController, bool>(
      PushEnabledController.new,
    );

final pushEnabledProvider = Provider<bool>(
  (ref) => ref.watch(pushEnabledControllerProvider).value ?? false,
);

/// The current OS permission state.
final pushPermissionProvider = FutureProvider<PushPermission>(
  (ref) => ref.watch(pushServiceProvider).currentPermission(),
);

/// Keeps the server's idea of this device in step with reality.
///
/// Registers a token when the user is signed in *and* has opted in, removes it
/// on sign-out or opt-out, and re-registers when the token rotates. Token
/// rotation is the failure everyone forgets: without it a device silently stops
/// receiving after a reinstall or a restore.
class PushRegistrar {
  PushRegistrar(this._ref) {
    _authSub = _ref.listen(currentUserProvider, (_, _) => _sync());
    _optInSub = _ref.listen(pushEnabledProvider, (_, _) => _sync());

    _refreshSub = _ref
        .read(pushServiceProvider)
        .onTokenRefresh()
        .listen(_onTokenRotated);
  }

  final Ref _ref;
  late final ProviderSubscription<Object?> _authSub;
  late final ProviderSubscription<Object?> _optInSub;
  late final StreamSubscription<String> _refreshSub;

  /// The token currently stored, and *who it was stored for*.
  ///
  /// The owner has to be remembered rather than read at removal time: on
  /// sign-out the listener fires when the current user is already null, so a
  /// delete that looks up the user finds nobody and silently does nothing —
  /// leaving a signed-out device still receiving.
  String? _registeredToken;
  String? _registeredUserId;

  /// Guards against overlapping runs. Sign-in and opt-in can land in the same
  /// frame, firing both listeners before the first write completes.
  bool _syncing = false;

  /// Tokens written and removed. For assertions.
  @visibleForTesting
  final List<String> registered = [];

  @visibleForTesting
  final List<String> unregistered = [];

  Future<void> _onTokenRotated(String token) async {
    final previous = _registeredToken;
    if (previous != null && previous != token) {
      await _remove(previous, _registeredUserId);
    }
    await _sync();
  }

  /// Brings the stored token in line with the current user and preference.
  Future<void> sync() => _sync();

  Future<void> _sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncOnce();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    final user = _ref.read(currentUserProvider);
    final optedIn = _ref.read(pushEnabledProvider);

    if (user == null || !optedIn) {
      final previous = _registeredToken;
      if (previous != null) await _remove(previous, _registeredUserId);
      return;
    }

    final token = await _ref.read(pushServiceProvider).token();
    if (token == null) return;

    // Already correct for *this* user. Comparing the token alone would skip
    // re-registration when a different account signs in on the same device,
    // leaving the previous owner receiving its notifications.
    if (token == _registeredToken && user.id == _registeredUserId) return;

    // A different owner means the old document has to go, or two accounts end
    // up registered for one device.
    final previous = _registeredToken;
    if (previous != null && _registeredUserId != user.id) {
      await _remove(previous, _registeredUserId);
    }

    try {
      await _ref
          .read(firestoreProvider)
          .doc(PushTokenLocation.document(user.id, token))
          .set({
            'token': token,
            'updatedAt': DateTime.now().toUtc(),
            'platform': defaultTargetPlatform.name,
          });
      _registeredToken = token;
      _registeredUserId = user.id;
      registered.add(token);
    } catch (error) {
      // A failed registration is not worth surfacing: the next sign-in or
      // token refresh retries, and the user cannot act on it anyway.
      AppLogger.instance.w('Could not register the push token: $error');
    }
  }

  /// Deletes [token] from [userId]'s device list.
  ///
  /// Takes the owner explicitly rather than reading the current user: the caller
  /// is usually reacting to that user having *just* signed out.
  Future<void> _remove(String token, String? userId) async {
    _registeredToken = null;
    _registeredUserId = null;
    unregistered.add(token);

    if (userId == null) return;
    try {
      await _ref
          .read(firestoreProvider)
          .doc(PushTokenLocation.document(userId, token))
          .delete();
    } catch (error) {
      AppLogger.instance.w('Could not remove the push token: $error');
    }
  }

  void dispose() {
    _authSub.close();
    _optInSub.close();
    _refreshSub.cancel();
  }
}

/// Kept alive for the app's lifetime by `TemplateApp`.
final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(ref);
  ref.onDispose(registrar.dispose);
  return registrar;
});

/// The route a notification tap should open, if any.
///
/// A stream rather than a callback so the router can listen without the push
/// layer knowing anything about routing.
final pushRouteProvider = StreamProvider<String>((ref) {
  final service = ref.watch(pushServiceProvider);

  return Stream<String>.multi((controller) {
    // A notification that launched a terminated app arrives here, not on the
    // opened stream — miss this and a cold-start tap goes nowhere.
    service.initialMessage().then((message) {
      final route = message?.route;
      if (route != null) controller.add(route);
    });

    final subscription = service.onMessageOpened().listen((message) {
      final route = message.route;
      if (route != null) controller.add(route);
    }, onError: controller.addError);

    controller.onCancel = subscription.cancel;
  });
});
