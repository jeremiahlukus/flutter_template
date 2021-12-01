// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:flutter_template/counter/model/counter.dart';

void main() {
  group('CounterModel', () {
    test('Counter should equal 1', () {
      // The model should be able to receive the following data:
      const counter = CounterModel(1);
      expect(counter.count, 1);
    });

    test('Counter toString should print out Object attributes', () {
      const counter = CounterModel(2);
      expect(counter.toString(), 'CounterModel: {count: 2}');
    });
  });
}
