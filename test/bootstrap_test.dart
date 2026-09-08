import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/bootstrap.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/errors/error_reporter.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// `bootstrap()` itself touches `Firebase.initializeApp` and `runApp`, so the
/// pieces it wires are extracted and tested here instead.
void main() {
  group('installErrorHandlers', () {
    test('attaches the environment to every subsequent report', () async {
      final harness = TestHarness.create(environment: AppEnvironment.staging);

      await installErrorHandlers(harness.container);

      expect(harness.errorReporter.customKeys['environment'], 'staging');
    });

    test('reports a framework error', () async {
      final harness = TestHarness.create();
      await installErrorHandlers(harness.container);
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('boom')),
      );

      expect(harness.errorReporter.errors, hasLength(1));
      expect(harness.errorReporter.errors.single.fatal, isTrue);
    });

    test('attaches the signed-in user, so a crash is traceable', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);

      await installErrorHandlers(harness.container);
      await pumpEventQueue();

      expect(harness.errorReporter.userId, 'user-1');
    });

    test('leaves the user id null while signed out', () async {
      final harness = TestHarness.create();
      await harness.container.read(authStateProvider.future);

      await installErrorHandlers(harness.container);
      await pumpEventQueue();

      expect(harness.errorReporter.userId, isNull);
    });

    test('clears the user id on sign-out', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);
      await installErrorHandlers(harness.container);
      await pumpEventQueue();
      expect(harness.errorReporter.userId, 'user-1');

      await harness.read(authControllerProvider.notifier).signOut();
      await pumpEventQueue();

      expect(harness.errorReporter.userId, isNull);
    });
  });

  group('reportZoneError', () {
    test('completes even with no container in scope', () {
      // A zone error can arrive before the app's container exists; this must not
      // throw on top of the error it is reporting.
      expect(
        () => reportZoneError(StateError('boom'), StackTrace.current),
        returnsNormally,
      );
    });

    test('handles an error with an empty stack trace', () {
      expect(
        () => reportZoneError(StateError('boom'), StackTrace.empty),
        returnsNormally,
      );
    });

    test('reports an uncaught zone error as fatal', () async {
      // 0010-R4. The two tests above only prove it does not throw, which a
      // handler that silently dropped the error would also satisfy.
      final reporter = RecordingErrorReporter();
      final error = StateError('escaped every try');

      reportZoneError(
        error,
        StackTrace.current,
        createContainer: () => ProviderContainer(
          overrides: [errorReporterProvider.overrideWithValue(reporter)],
        ),
      );
      await pumpEventQueue();

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.error, same(error));
      expect(
        reporter.errors.single.fatal,
        isTrue,
        reason: 'An error that escaped the whole app is fatal by definition',
      );
    });

    test('disposes the container it created', () async {
      // It builds a container per error; leaking one per crash would matter in
      // a crash loop.
      late ProviderContainer created;
      reportZoneError(
        StateError('boom'),
        StackTrace.current,
        createContainer: () {
          return created = ProviderContainer(
            overrides: [
              errorReporterProvider.overrideWithValue(
                RecordingErrorReporter(),
              ),
            ],
          );
        },
      );

      // Reading a disposed container throws, which is how we can tell.
      expect(() => created.read(errorReporterProvider), throwsStateError);
    });
  });
}
