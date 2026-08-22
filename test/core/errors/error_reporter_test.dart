import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/errors/error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  final details = FlutterErrorDetails(
    exception: StateError('boom'),
    stack: StackTrace.current,
    context: ErrorDescription('while building'),
  );

  group('RecordingErrorReporter', () {
    late RecordingErrorReporter reporter;

    setUp(() => reporter = RecordingErrorReporter());

    test('starts empty', () {
      expect(reporter.errors, isEmpty);
      expect(reporter.breadcrumbs, isEmpty);
      expect(reporter.customKeys, isEmpty);
      expect(reporter.userId, isNull);
    });

    test('records a non-fatal error with its reason', () async {
      await reporter.recordError(
        StateError('bad'),
        StackTrace.current,
        reason: 'while saving',
      );

      expect(reporter.errors.single.reason, 'while saving');
      expect(reporter.errors.single.fatal, isFalse);
    });

    test('records a fatal error', () async {
      await reporter.recordError(StateError('bad'), null, fatal: true);
      expect(reporter.errors.single.fatal, isTrue);
    });

    test('records a framework error as fatal', () async {
      await reporter.recordFlutterError(details);

      expect(reporter.errors.single.fatal, isTrue);
      expect(reporter.errors.single.error, details.exception);
      expect(reporter.errors.single.reason, contains('while building'));
    });

    test('stores and clears the user id', () async {
      await reporter.setUserId('u1');
      expect(reporter.userId, 'u1');

      await reporter.setUserId(null);
      expect(reporter.userId, isNull);
    });

    test('accumulates breadcrumbs in order', () async {
      await reporter.log('first');
      await reporter.log('second');

      expect(reporter.breadcrumbs, ['first', 'second']);
    });

    test('overwrites a repeated custom key', () async {
      await reporter.setCustomKey('env', 'dev');
      await reporter.setCustomKey('env', 'prod');

      expect(reporter.customKeys, {'env': 'prod'});
    });
  });

  group('NoopErrorReporter', () {
    const reporter = NoopErrorReporter();

    test('every method completes without doing anything', () async {
      await expectLater(reporter.recordError(StateError('x'), null), completes);
      await expectLater(reporter.recordFlutterError(details), completes);
      await expectLater(reporter.setUserId('u'), completes);
      await expectLater(reporter.setCustomKey('k', 'v'), completes);
      await expectLater(reporter.log('m'), completes);
    });
  });

  group('CrashlyticsErrorReporter', () {
    late _MockCrashlytics crashlytics;
    late CrashlyticsErrorReporter reporter;

    setUpAll(() {
      registerFallbackValue(StackTrace.empty);
      registerFallbackValue(
        FlutterErrorDetails(exception: StateError('fallback')),
      );
    });

    setUp(() {
      crashlytics = _MockCrashlytics();
      reporter = CrashlyticsErrorReporter(crashlytics);
    });

    test('forwards an error with its reason and fatal flag', () async {
      when(
        () => crashlytics.recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: any<String>(named: 'reason'),
          fatal: any<bool>(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      final error = StateError('bad');
      await reporter.recordError(error, null, reason: 'ctx', fatal: true);

      verify(
        () => crashlytics.recordError(error, null, reason: 'ctx', fatal: true),
      ).called(1);
    });

    test('forwards a framework error as fatal', () async {
      when(
        () => crashlytics.recordFlutterFatalError(any()),
      ).thenAnswer((_) async {});

      await reporter.recordFlutterError(details);

      verify(() => crashlytics.recordFlutterFatalError(details)).called(1);
    });

    test('forwards the user id', () async {
      when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});

      await reporter.setUserId('u1');

      verify(() => crashlytics.setUserIdentifier('u1')).called(1);
    });

    test('a null user id becomes an empty identifier', () async {
      when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});

      await reporter.setUserId(null);

      // Crashlytics has no "clear"; the empty string is the documented way.
      verify(() => crashlytics.setUserIdentifier('')).called(1);
    });

    test('forwards custom keys and breadcrumbs', () async {
      when(
        () => crashlytics.setCustomKey(any(), any()),
      ).thenAnswer((_) async {});
      when(() => crashlytics.log(any())).thenAnswer((_) async {});

      await reporter.setCustomKey('env', 'prod');
      await reporter.log('saved a note');

      verify(() => crashlytics.setCustomKey('env', 'prod')).called(1);
      verify(() => crashlytics.log('saved a note')).called(1);
    });

    group('never lets reporting break the caller', () {
      // A throw from the reporter would take down whatever action was being
      // reported on — the exact opposite of the point.
      test('recordError swallows a throw', () async {
        when(
          () => crashlytics.recordError(
            any<Object>(),
            any<StackTrace>(),
            reason: any<String>(named: 'reason'),
            fatal: any<bool>(named: 'fatal'),
          ),
        ).thenThrow(Exception('offline'));

        await expectLater(
          reporter.recordError(StateError('x'), null),
          completes,
        );
      });

      test('recordFlutterError swallows a throw', () async {
        when(
          () => crashlytics.recordFlutterFatalError(any()),
        ).thenThrow(Exception('offline'));

        await expectLater(reporter.recordFlutterError(details), completes);
      });

      test('setUserId swallows a throw', () async {
        when(
          () => crashlytics.setUserIdentifier(any()),
        ).thenThrow(Exception('offline'));

        await expectLater(reporter.setUserId('u'), completes);
      });

      test('setCustomKey swallows a throw', () async {
        when(
          () => crashlytics.setCustomKey(any(), any()),
        ).thenThrow(Exception('offline'));

        await expectLater(reporter.setCustomKey('k', 'v'), completes);
      });

      test('log swallows a throw', () async {
        when(() => crashlytics.log(any())).thenThrow(Exception('offline'));

        await expectLater(reporter.log('m'), completes);
      });
    });
  });

  group('errorReporterProvider', () {
    test('is a no-op where the environment disables reporting', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.dev),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(errorReporterProvider), isA<NoopErrorReporter>());
    });

    test('uses Crashlytics where the environment enables it', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.prod),
          ),
          firebaseCrashlyticsProvider.overrideWithValue(_MockCrashlytics()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(errorReporterProvider),
        isA<CrashlyticsErrorReporter>(),
      );
    });
  });
}
