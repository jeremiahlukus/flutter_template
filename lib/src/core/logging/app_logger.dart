import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Thin wrapper around [Logger] so call sites never construct their own.
///
/// In release builds the level is raised to [Level.warning] to keep noise (and
/// any accidental PII) out of production logs.
abstract final class AppLogger {
  static Logger? _override;

  static Logger get instance =>
      _override ??
      (_instance ??= Logger(
        level: kReleaseMode ? Level.warning : Level.debug,
        printer: PrettyPrinter(),
      ));

  static Logger? _instance;

  /// Installs [logger] in place of the default. Pass null to restore it.
  ///
  /// Only tests should call this; production code takes [instance].
  @visibleForTesting
  static void useLogger(Logger? logger) {
    _override = logger;
    // Drop the memoised default too, so a later restore rebuilds it with the
    // current `kReleaseMode` rather than handing back a stale instance.
    _instance = null;
  }
}
