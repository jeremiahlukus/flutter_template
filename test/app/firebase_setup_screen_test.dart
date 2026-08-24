import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/firebase_options.dart';
import 'package:flutter_template/src/app/firebase_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The screen shown when Firebase is not configured.
///
/// It has to work in exactly the situation where nothing else does, so it takes
/// no providers and no Firebase — these tests pump it bare on purpose.
void main() {
  Future<void> pump(WidgetTester tester, {Object? error}) =>
      tester.pumpWidget(FirebaseSetupApp(error: error));

  group('FirebaseNotConfigured', () {
    test('names the command that fixes it', () {
      const failure = FirebaseNotConfigured();

      expect(failure.toString(), contains('flutterfire configure'));
      expect(failure.toString(), contains('firebase_options.dart'));
    });

    test('points at the checklist', () {
      expect(const FirebaseNotConfigured().toString(), contains('task.md'));
    });

    test('the committed placeholder throws it', () {
      // Asserts the *placeholder*, so it stops being true once you run
      // `flutterfire configure` — the generated file throws `UnsupportedError`
      // instead. Delete this one test at that point; the rest of the file, and
      // the setup screen itself, keep working because `bootstrap` catches
      // anything. task.md Milestone 0 lists this.
      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsA(isA<FirebaseNotConfigured>()),
      );
    });
  });

  group('rendering', () {
    testWidgets('builds with no provider scope at all', (tester) async {
      // If this ever needs a ProviderScope, it can no longer do its job.
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('setup_title')), findsOne);
    });

    testWidgets('says the app needs Firebase', (tester) async {
      await pump(tester);

      expect(find.text('Firebase setup required'), findsOne);
      expect(find.textContaining('needs Firebase to run'), findsOne);
    });

    testWidgets('shows both setup commands', (tester) async {
      await pump(tester);

      expect(find.text('dart pub global activate flutterfire_cli'), findsOne);
      expect(find.text('flutterfire configure'), findsOne);
    });

    testWidgets('tells the reader to restart afterwards', (tester) async {
      await pump(tester);

      expect(find.textContaining('rerun the app'), findsOne);
    });

    testWidgets('points at the checklist', (tester) async {
      await pump(tester);

      expect(find.textContaining('task.md'), findsOne);
    });

    testWidgets('hides the error section when there is no error', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(const ValueKey('setup_error_details')), findsNothing);
    });

    testWidgets('offers collapsed error details when there is an error', (
      tester,
    ) async {
      await pump(tester, error: const FirebaseNotConfigured());

      expect(find.byKey(const ValueKey('setup_error_details')), findsOne);
      // Collapsed: the instructions are what the reader needs first.
      expect(find.textContaining('flutterfire configure'), findsWidgets);
    });

    testWidgets('expanding the details reveals the raw error', (tester) async {
      await pump(tester, error: StateError('something very specific'));

      await tester.tap(find.byKey(const ValueKey('setup_error_details')));
      await tester.pumpAndSettle();

      expect(find.textContaining('something very specific'), findsOne);
    });
  });

  group('copy buttons', () {
    testWidgets('copy the command to the clipboard', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pump(tester);
      await tester.tap(
        find.byKey(const ValueKey('copy_flutterfire configure')),
      );
      await tester.pumpAndSettle();

      expect(copied, ['flutterfire configure']);
      expect(find.text('Copied to clipboard'), findsOne);
    });
  });

  group('robustness', () {
    testWidgets('renders on a narrow phone without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pump(tester, error: const FirebaseNotConfigured());

      // Scrollable on purpose: this content must never be clipped, because it is
      // the only thing telling the reader how to proceed.
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOne);
    });

    testWidgets('renders on a wide desktop window', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pump(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('setup_title')), findsOne);
    });

    testWidgets('follows the platform locale', (tester) async {
      // There is no provider graph here to hold a locale preference, so the
      // screen has to fall back to the device language — which is correct: this
      // is a developer-facing message shown before the app can run.
      // `MaterialApp` resolves from `locales`, not `locale`, so both are set.
      tester.platformDispatcher
        ..localeTestValue = const Locale('es')
        ..localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await pump(tester);

      expect(find.text('Se requiere configurar Firebase'), findsOne);
      expect(find.text('Firebase setup required'), findsNothing);
    });

    testWidgets('falls back to English for an unsupported locale', (
      tester,
    ) async {
      tester.platformDispatcher
        ..localeTestValue = const Locale('kl')
        ..localesTestValue = const [Locale('kl')];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await pump(tester);

      expect(find.text('Firebase setup required'), findsOne);
    });
  });
}
