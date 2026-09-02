import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';

/// Whether the user has granted notification permission.
enum PushPermission {
  granted,
  denied,

  /// iOS "provisional" — notifications arrive quietly until the user promotes
  /// them. Worth distinguishing: it is not a denial, and re-prompting is wrong.
  provisional,

  /// Not asked yet.
  notDetermined;

  /// Whether a message can actually reach the user.
  bool get canDeliver =>
      this == PushPermission.granted || this == PushPermission.provisional;

  /// Whether asking again is meaningful. On both platforms a hard denial is
  /// final until the user changes it in system settings.
  bool get canPrompt => this == PushPermission.notDetermined;
}

/// A received push, reduced to what the app acts on.
@immutable
class PushMessage {
  const PushMessage({
    required this.data,
    this.title,
    this.body,
    this.messageId,
  });

  factory PushMessage.fromRemote(RemoteMessage message) => PushMessage(
    data: message.data,
    title: message.notification?.title,
    body: message.notification?.body,
    messageId: message.messageId,
  );

  /// Custom payload. The only part a server fully controls on both platforms.
  final Map<String, dynamic> data;
  final String? title;
  final String? body;
  final String? messageId;

  /// Deep-link target, by convention. Null when the payload carries none.
  String? get route {
    final value = data['route'];
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  String toString() => 'PushMessage($messageId, route: $route)';
}

/// Push notifications, in the app's own vocabulary.
///
/// An interface for the usual reason — `FirebaseMessaging` needs a platform
/// channel and an APNs certificate, so nothing about it runs in a widget test.
/// It also lets a fork swap the transport without touching feature code.
abstract interface class PushService {
  Future<PushPermission> currentPermission();

  /// Prompts if the platform allows it, and returns the resulting state.
  Future<PushPermission> requestPermission();

  /// The device token, or null when permission is missing.
  Future<String?> token();

  /// Emits whenever the token is rotated — which the server must be told about,
  /// or the device silently stops receiving.
  Stream<String> onTokenRefresh();

  /// Messages that arrive while the app is in the foreground.
  Stream<PushMessage> onForegroundMessage();

  /// Fires when a notification is tapped and opens the app.
  Stream<PushMessage> onMessageOpened();

  /// The notification that launched a terminated app, if any.
  Future<PushMessage?> initialMessage();

  Future<void> deleteToken();
}

class FirebasePushService implements PushService {
  const FirebasePushService(this._messaging);

  final FirebaseMessaging _messaging;

  /// Every platform status maps to one of ours, with **no wildcard case**.
  ///
  /// The exhaustiveness is the point: `firebase_messaging` 16.6.0 added
  /// `deniedPermanently`, and because this switch has no `_ =>` fallback the
  /// analyzer failed the build and forced the decision. A wildcard would have
  /// silently folded a new OS state into whatever came first. → 0020-R16
  ///
  /// `deniedPermanently` collapses onto [PushPermission.denied] because the two
  /// are indistinguishable to this app: neither can deliver, and we do not
  /// re-prompt on either. It is Android 13+ only — Apple reports permanent
  /// denial as plain `denied`.
  ///
  /// Worth knowing, and deliberately *not* acted on here: upstream now documents
  /// plain `denied` on Android 13+ as possibly re-promptable, and suggests
  /// preferring `requestPermission()` over sending the user to system settings.
  /// `PushPermission.denied.canPrompt` is `false`, so we do the opposite. That is
  /// a UX change with its own spec, not something to fold into a version bump.
  static PushPermission _map(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized => PushPermission.granted,
    AuthorizationStatus.provisional => PushPermission.provisional,
    AuthorizationStatus.denied => PushPermission.denied,
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  Future<PushPermission> currentPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _map(settings.authorizationStatus);
    } catch (error) {
      AppLogger.instance.w('Could not read notification settings: $error');
      return PushPermission.notDetermined;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      return _map(settings.authorizationStatus);
    } catch (error) {
      AppLogger.instance.w('Notification permission request failed: $error');
      return PushPermission.denied;
    }
  }

  @override
  Future<String?> token() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      // Commonly an APNs token that is not ready yet on a cold iOS launch.
      AppLogger.instance.w('Could not read the push token: $error');
      return null;
    }
  }

  @override
  Stream<String> onTokenRefresh() => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> onForegroundMessage() =>
      FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  @override
  Stream<PushMessage> onMessageOpened() =>
      FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushMessage.fromRemote(message);
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (error) {
      AppLogger.instance.w('Could not delete the push token: $error');
    }
  }
}

/// Controllable implementation for tests.
@visibleForTesting
class FakePushService implements PushService {
  FakePushService({
    this.permission = PushPermission.notDetermined,
    this.permissionAfterPrompt = PushPermission.granted,
    this.currentToken = 'fake-token',
  });

  PushPermission permission;
  PushPermission permissionAfterPrompt;
  String? currentToken;

  int promptCount = 0;
  int deleteCount = 0;

  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  final _refresh = StreamController<String>.broadcast();

  PushMessage? launchMessage;

  @override
  Future<PushPermission> currentPermission() async => permission;

  @override
  Future<PushPermission> requestPermission() async {
    promptCount++;
    return permission = permissionAfterPrompt;
  }

  @override
  Future<String?> token() async => permission.canDeliver ? currentToken : null;

  @override
  Stream<String> onTokenRefresh() => _refresh.stream;

  @override
  Stream<PushMessage> onForegroundMessage() => _foreground.stream;

  @override
  Stream<PushMessage> onMessageOpened() => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => launchMessage;

  @override
  Future<void> deleteToken() async {
    deleteCount++;
    currentToken = null;
  }

  void emitForeground(PushMessage message) => _foreground.add(message);

  void emitOpened(PushMessage message) => _opened.add(message);

  void rotateToken(String token) {
    currentToken = token;
    _refresh.add(token);
  }

  Future<void> dispose() async {
    await _foreground.close();
    await _opened.close();
    await _refresh.close();
  }
}

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final pushServiceProvider = Provider<PushService>(
  (ref) => FirebasePushService(ref.watch(firebaseMessagingProvider)),
);
