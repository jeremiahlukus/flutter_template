import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/app.dart';
import 'package:flutter_template/src/app/firebase_setup_screen.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/errors/error_reporter.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';

/// Boots the application.
///
/// Everything that must happen before the first frame lives here so that
/// `main.dart` stays a one-liner and tests can pump [TemplateApp] directly.
///
/// [firebaseOptions] is a *callback*, not a value, so that a placeholder
/// `firebase_options.dart` that throws is caught here and turned into
/// [FirebaseSetupApp] rather than killing the process before anything renders.
Future<void> bootstrap({
  required FirebaseOptions Function() firebaseOptions,
}) async {
  return runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      Object? setupFailure;
      try {
        await Firebase.initializeApp(options: firebaseOptions());
      } catch (error, stackTrace) {
        AppLogger.instance.e(
          'Firebase failed to initialise; showing the setup screen',
          error: error,
          stackTrace: stackTrace,
        );
        setupFailure = error;
      }

      if (setupFailure != null) {
        // Nothing downstream works without Firebase, so do not build the
        // provider graph at all — just say what to do about it.
        runApp(FirebaseSetupApp(error: setupFailure));
        return;
      }

      // The one database instance for the process. Constructed here rather than
      // lazily in the provider so a fork can prime anything it needs before the
      // first frame — read a persisted text scale, say, and paint at the right
      // size instead of snapping to it a frame later.
      //
      // `appDatabaseProvider` throws unless overridden, which is what stops a
      // second `AppDatabase` ever being opened on the same file.
      final database = AppDatabase();

      // Built before `runApp` so the error handlers below report through the
      // same `ErrorReporter` the app uses, and so an error thrown during the
      // first frame is still captured.
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      await installErrorHandlers(container);

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const TemplateApp(),
        ),
      );
    },
    reportZoneError,
  );
}

/// Wires framework-error reporting and attaches build metadata.
///
/// Extracted from [bootstrap] so it is testable without `Firebase.initializeApp`
/// or `runApp` — those two are why `bootstrap` itself has no unit test.
@visibleForTesting
Future<void> installErrorHandlers(ProviderContainer container) async {
  final reporter = container.read(errorReporterProvider);
  final config = container.read(appConfigProvider);

  await reporter.setCustomKey('environment', config.environment.key);

  // Attach the signed-in user to every subsequent report, so a crash can be
  // traced to an account. Cleared on sign-out by the same listener.
  container.listen<AsyncValue<AppUser?>>(
    authStateProvider,
    (_, next) => reporter.setUserId(next.value?.id),
    fireImmediately: true,
  );

  FlutterError.onError = (details) {
    AppLogger.instance.e(
      'Uncaught framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    reporter.recordFlutterError(details);
  };
}

/// Handles an error that escaped every `try` in the app.
///
/// Reads a fresh reporter rather than closing over one, so a zone error thrown
/// *before* the container exists is still reported.
@visibleForTesting
void reportZoneError(Object error, StackTrace stackTrace) {
  AppLogger.instance.e(
    'Uncaught zone error',
    error: error,
    stackTrace: stackTrace,
  );

  final container = ProviderContainer();
  try {
    container
        .read(errorReporterProvider)
        .recordError(error, stackTrace, fatal: true);
  } finally {
    container.dispose();
  }
}
