class CounterModel {
  const CounterModel(this.count);
  final int count;

  @override
  String toString() {
    return 'Counter: {count: $count}';
  }
}
