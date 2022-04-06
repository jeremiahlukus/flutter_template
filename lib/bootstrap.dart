// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/firebase_options.dart';

// Package imports:
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Project imports:
import 'package:flutter_template/utils/provider_logger.dart';

Logger logger = Logger();
Future<void> bootstrap(Widget Function() builder, {String? sentryUrl}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) {
    final errorMap = <String, String>{
      'error': details.exceptionAsString(),
      'stackTrace': details.stack.toString(),
    };
    Sentry.captureException(
      details.exceptionAsString(),
      stackTrace: details.stack.toString(),
    );
    logger.e(errorMap);
  };
  await runZonedGuarded(
    () async {
      await SentryFlutter.init(
        (options) {
          options
            ..dsn = sentryUrl
            ..tracesSampleRate = 1.0;
          // Set tracesSampleRate to 1.0 to capture 100% of transactions
          // for performance monitoring.
          // We recommend adjusting this value in production.
        },
        appRunner: () => runApp(
          ProviderScope(observers: [ProviderLogger()], child: builder()),
        ),
      );
    },
    (error, stackTrace) {
      final errorMap = <String, String>{
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      };
      Sentry.captureException(
        error.toString(),
        stackTrace: stackTrace.toString(),
      );
      logger.e(errorMap);
    },
  );
}
