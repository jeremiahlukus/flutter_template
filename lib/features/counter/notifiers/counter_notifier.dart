// Package imports:
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/features/counter/model/counter.dart';

class CounterNotifier extends StateNotifier<CounterModel> {
  CounterNotifier() : super(_initialValue);
  static const _initialValue = CounterModel(0);
  void increment() {
    state = CounterModel(state.count + 1);
  }

  void decrement() {
    state = CounterModel(state.count - 1);
  }
}
