import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:logger/logger.dart';

import 'helpers/firebase_core_mock.dart';

/// Runs once for every test file in this directory tree.
///
/// Silences [AppLogger] so the expected-failure paths — which log warnings by
/// design — do not bury real test output in noise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLogger.useLogger(Logger(level: Level.off));

  // The suite legitimately opens many isolated in-memory databases; drift's
  // "opened twice" advice is aimed at app code, not tests.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // `firebase_ui_auth` refuses to build until Firebase Core has initialised, so
  // stub it for the whole suite rather than per sign-in test.
  await setUpMockFirebaseCore();

  await testMain();
}
