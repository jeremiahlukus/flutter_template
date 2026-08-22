import 'package:flutter_template/bootstrap.dart';
import 'package:flutter_template/firebase_options.dart';

void main() => bootstrap(
  // Passed as a callback so an unconfigured placeholder is caught by
  // `bootstrap` and shown as the setup screen, not thrown at startup.
  firebaseOptions: () => DefaultFirebaseOptions.currentPlatform,
);
