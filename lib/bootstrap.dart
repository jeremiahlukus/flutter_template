import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_template/utils/provider_logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> bootstrap(Widget Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await runZonedGuarded(
    () async {
      runApp(ProviderScope(observers: [ProviderLogger()], child: builder()));
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}
