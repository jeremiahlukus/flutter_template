// A CLI tool's whole job is writing to stdout.
// ignore_for_file: avoid_print
import 'dart:io';

/// Overwrites `lib/firebase_options.dart` with a compile-only stub.
///
/// The committed file deliberately throws, so a misconfigured app fails loudly
/// instead of emitting confusing `FirebaseException`s. That is right for
/// developers and wrong for CI, where the goal is only to prove the app
/// *compiles*. This writes credentials that are syntactically valid and
/// obviously fake.
///
/// Never run this locally — use `flutterfire configure` instead.
void main() {
  const path = 'lib/firebase_options.dart';

  File(path).writeAsStringSync('''
// GENERATED FOR CI BY tool/stub_firebase_options.dart — DO NOT COMMIT.
// Run `flutterfire configure` to produce the real file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'ci-stub-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ci-stub-project',
    storageBucket: 'ci-stub-project.appspot.com',
  );
}
''');

  print('Wrote CI stub to $path');
}
