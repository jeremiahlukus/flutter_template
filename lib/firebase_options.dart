// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Placeholder Firebase configuration.
///
/// This file is normally **generated**. Before running the app for the first
/// time, replace it by running:
///
/// ```sh
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// ```
///
/// Until then [currentPlatform] throws, rather than returning fake credentials
/// that would produce confusing `FirebaseException`s at the first auth or
/// Firestore call. `bootstrap()` catches this and renders
/// `FirebaseSetupScreen`, so the app still launches and explains itself.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw FirebaseNotConfigured();
}

/// Thrown by the placeholder [DefaultFirebaseOptions].
///
/// A named type rather than a bare `StateError` so `bootstrap` can tell "you
/// have not configured Firebase" apart from "Firebase is configured but failed
/// to start", and so a test can assert on the distinction.
class FirebaseNotConfigured implements Exception {
  const FirebaseNotConfigured();

  @override
  String toString() =>
      'Firebase is not configured. Run `flutterfire configure` to regenerate '
      'lib/firebase_options.dart, then rerun the app. '
      'See task.md > Milestone 0 for the full checklist.';
}
