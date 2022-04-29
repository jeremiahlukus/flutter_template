// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/core/infrastructure/provider_logger.dart';

class MockLogger extends Mock implements Logger {}

final testProvider = Provider((ref) => 'test');
final testProviderContainer = ProviderContainer();

void main() {
  setUpAll(() {
    registerFallbackValue({
      'didUpdateProvider': {'type': 'provider', 'new_value': 'new_value', 'old_value': 'old_value'}
    });
  });

  group('ProviderLogger', () {
    group('.didUpdateProvider', () {
      test("calls Logger's information log", () {
        final Logger mockLogger = MockLogger();
        final providerLogger = ProviderLogger(loggerInstance: mockLogger);

        const previousValue = 'previousValue';
        const newValue = 'newValue';

        providerLogger.didUpdateProvider.call(testProvider, previousValue, newValue, testProviderContainer);

        verify(
          () => mockLogger.i(any<dynamic>()),
        ).called(1);
      });
    });

    group('.providerDidFail', () {
      test("calls Logger's error log", () {
        final Logger mockLogger = MockLogger();
        final providerLogger = ProviderLogger(loggerInstance: mockLogger);

        const error = 'error';
        final stackTrace = StackTrace.fromString('stackTraceString');

        providerLogger.providerDidFail.call(testProvider, error, stackTrace, testProviderContainer);

        verify(
          () => mockLogger.e(any<dynamic>()),
        ).called(1);
      });
    });
  });
}
