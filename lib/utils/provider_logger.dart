// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProviderLogger extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    log('providerDidFail(${provider.runtimeType}, $error, $stackTrace)');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    log(
      'didUpdateProvider: { '
      'type: {${provider.runtimeType}} '
      'new_value: { ${newValue.toString()} } '
      'old_value: { ${previousValue.toString()} } '
      '}',
    );
  }
}
