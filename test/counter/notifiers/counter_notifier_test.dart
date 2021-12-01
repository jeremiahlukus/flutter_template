// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Project imports:
import 'package:flutter_template/counter/counter.dart';
import 'package:flutter_template/counter/model/counter.dart';

class MockStateNotifier extends Mock implements CounterNotifier {}

class Listener extends Mock {
  void call(int value);
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterModel>(
  (ref) => CounterNotifier(),
);

void main() {
  group('CounterNotifier', () {
    test('defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(counterProvider).count, equals(0));
    });

    test('Add 1 when value is incremented', () {
      // An object that will allow us to read providers
      // Do not share this between tests.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(counterProvider).count, equals(0));
      // We increment the value
      container.read(counterProvider.notifier).increment();
      expect(container.read(counterProvider).count, equals(1));
    });

    test('Subtract 1 when value is decremented', () {
      // An object that will allow us to read providers
      // Do not share this between tests.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(counterProvider).count, equals(0));
      // We increment the value
      container.read(counterProvider.notifier).decrement();
      expect(container.read(counterProvider).count, equals(-1));
    });
  });
}