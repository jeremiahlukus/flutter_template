// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:flutter_template/utils/provider_logger.dart';
// Package imports:
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

Logger logger = Logger();
Future<void> bootstrap(Widget Function() builder) async {
  FlutterError.onError = (details) {
    final errorMap = <String, String>{
      'error': details.exceptionAsString(),
      'stackTrace': details.stack.toString(),
    };
    logger.e(errorMap);
  };

  await runZonedGuarded(
    () async {
      runApp(ProviderScope(observers: [ProviderLogger()], child: builder()));
    },
    (error, stackTrace) {
      final errorMap = <String, String>{
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      };
      logger.e(errorMap);
    },
  );
}
