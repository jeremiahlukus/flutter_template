// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  GENERATED FILE — do not add anything to it.                              ║
// ║                                                                          ║
// ║  `flutterfire configure` overwrites this file wholesale. Anything you add ║
// ║  here disappears the first time someone runs it, and the build breaks on  ║
// ║  a type that was there a minute ago. Put app code anywhere else.          ║
// ╚══════════════════════════════════════════════════════════════════════════╝
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_template/src/app/firebase_setup_screen.dart'
    show FirebaseNotConfigured;

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
