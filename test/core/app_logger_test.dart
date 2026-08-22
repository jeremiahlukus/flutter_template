import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Records every log line, so tests can assert on output.
class _CapturingOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  tearDown(() => AppLogger.useLogger(null));

  test('provides a logger without configuration', () {
    expect(AppLogger.instance, isA<Logger>());
  });

  test('returns the same default instance on repeated reads', () {
    expect(AppLogger.instance, same(AppLogger.instance));
  });

  test('useLogger installs a replacement', () {
    final replacement = Logger(level: Level.off);
    AppLogger.useLogger(replacement);

    expect(AppLogger.instance, same(replacement));
  });

  test('useLogger(null) restores the default', () {
    AppLogger.useLogger(Logger(level: Level.off));
    AppLogger.useLogger(null);

    expect(AppLogger.instance, isA<Logger>());
  });

  test('the restored default is a fresh instance', () {
    final original = AppLogger.instance;
    AppLogger.useLogger(Logger(level: Level.off));
    AppLogger.useLogger(null);

    // The memoised default is dropped so it is rebuilt against the current
    // build mode rather than handed back stale.
    expect(AppLogger.instance, isNot(same(original)));
  });

  test('an installed logger actually receives output', () {
    final output = _CapturingOutput();
    AppLogger.useLogger(
      Logger(level: Level.trace, output: output, printer: SimplePrinter()),
    );

    AppLogger.instance.w('something went sideways');

    expect(output.lines.join(), contains('something went sideways'));
  });

  test('errors and stack traces reach the output', () {
    final output = _CapturingOutput();
    AppLogger.useLogger(
      Logger(level: Level.trace, output: output, printer: SimplePrinter()),
    );

    AppLogger.instance.e(
      'boom',
      error: StateError('bad state'),
      stackTrace: StackTrace.current,
    );

    expect(output.lines.join(), contains('boom'));
    expect(output.lines.join(), contains('bad state'));
  });
}
