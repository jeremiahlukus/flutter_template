// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:platform/platform.dart';

class BackendConstants {
  /// Returns [LocalPlatform] by default
  /// Swap it during tests with [FakePlatform] and ensure to set it to null in
  /// the tear down
  @visibleForTesting
  static Platform getPlatform() => _platform ?? const LocalPlatform();

  static Platform? _platform;

  // ignore: avoid_setters_without_getters
  static set platform(Platform? platformArgument) => _platform = platformArgument;

  /// Returns [kDebugMode]] by default
  /// Swap it during tests with a [bool] or and ensure to set it to null in
  /// the tear down
  static bool getIsDebugMode() => _isDebugMode ?? kDebugMode;

  static bool? _isDebugMode;

  // ignore: avoid_setters_without_getters
  static set isDebugMode(bool? isDebugModeArgument) => _isDebugMode = isDebugModeArgument;

  String backendBaseUrl() {
    if (getIsDebugMode()) {
      final isAndroid = getPlatform().isAndroid;
      return isAndroid ? '10.0.2.2:3000' : '127.0.0.1:3000';
    } else {
      return 'someUrl';
    }
  }
}
