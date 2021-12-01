// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Package imports:
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Project imports:
import 'package:flutter_template/bootstrap.dart';

class ProviderLogger extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final errorMap = <String, String>{
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    };
    Sentry.captureException(
      error.toString(),
      stackTrace: stackTrace.toString(),
    );
    logger.e(errorMap);
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final loggerMessage = {
      'didUpdateProvider': {
        'type': provider.runtimeType,
        'new_value': newValue.toString(),
        'old_value': previousValue.toString()
      }
    };
    logger.i(loggerMessage);
  }
}
