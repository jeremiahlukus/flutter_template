import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';

/// Crash and non-fatal error reporting.
///
/// An interface rather than direct Crashlytics calls for the same reason as
/// analytics: a report must never be the reason an action fails, and the test
/// suite needs to assert on what *would* have been sent without a Firebase
/// project.
abstract interface class ErrorReporter {
  /// Reports a caught error that the user recovered from.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Reports an uncaught framework error.
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Attaches the signed-in user, so a report can be traced to an account.
  Future<void> setUserId(String? id);

  /// Attaches a key/value that shows up on every subsequent report.
  Future<void> setCustomKey(String key, Object value);

  /// Adds a breadcrumb to the log attached to the next report.
  Future<void> log(String message);
}

/// Production implementation backed by Firebase Crashlytics.
class CrashlyticsErrorReporter implements ErrorReporter {
  const CrashlyticsErrorReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> _guard(String label, Future<void> Function() body) async {
    try {
      await body();
    } catch (error, stackTrace) {
      // Reporting the reporter's own failure would recurse; log and drop.
      AppLogger.instance.w(
        'Crash reporting call "$label" failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) => _guard(
    'recordError',
    () => _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    ),
  );

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) => _guard(
    'recordFlutterError',
    () => _crashlytics.recordFlutterFatalError(details),
  );

  @override
  Future<void> setUserId(String? id) => _guard(
    'setUserId',
    () => _crashlytics.setUserIdentifier(id ?? ''),
  );

  @override
  Future<void> setCustomKey(String key, Object value) => _guard(
    'setCustomKey',
    () => _crashlytics.setCustomKey(key, value),
  );

  @override
  Future<void> log(String message) =>
      _guard('log', () => _crashlytics.log(message));
}

/// Drops every report. Used in dev, and wherever
/// [AppConfig.crashReportingEnabled] is false.
///
/// A no-op rather than a conditional at each call site, so feature code never has
/// to ask whether reporting is on.
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> log(String message) async {}
}

/// Records everything in memory, for tests.
@visibleForTesting
class RecordingErrorReporter implements ErrorReporter {
  final List<ReportedError> errors = [];
  final List<String> breadcrumbs = [];
  final Map<String, Object> customKeys = {};

  String? userId;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    errors.add(ReportedError(error, reason: reason, fatal: fatal));
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    errors.add(
      ReportedError(
        details.exception,
        reason: details.context?.toString(),
        fatal: true,
      ),
    );
  }

  @override
  Future<void> setUserId(String? id) async => userId = id;

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> log(String message) async => breadcrumbs.add(message);
}

@immutable
class ReportedError {
  const ReportedError(this.error, {this.reason, this.fatal = false});

  final Object error;
  final String? reason;
  final bool fatal;

  @override
  String toString() => 'ReportedError($error, reason: $reason, fatal: $fatal)';
}

final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>(
  (ref) => FirebaseCrashlytics.instance,
);

/// Resolves to a real reporter only where the environment allows it.
final errorReporterProvider = Provider<ErrorReporter>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.crashReportingEnabled) return const NoopErrorReporter();
  return CrashlyticsErrorReporter(ref.watch(firebaseCrashlyticsProvider));
});
