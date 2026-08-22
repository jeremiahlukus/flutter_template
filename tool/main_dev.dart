// QA entrypoint. Not shipped.
//
// Registers the `flutter_skill` VM Service extensions that drive the on-device
// flows in `flutter-skill.md`, then hands off to the normal [bootstrap].
//
// This lives in `tool/` rather than `lib/` on purpose. `flutter_skill` is a
// dev_dependency, and Dart forbids `lib/` from importing one — which is the
// right constraint: QA tooling must not be reachable from production code, and
// `lib/main.dart` stays free of it.
//
// Run it with:
//
// ```sh
// flutter run -t tool/main_dev.dart \
//   --dart-define=APP_ENV=staging \
//   --vm-service-port=50123 --disable-service-auth-codes
// ```
import 'package:flutter_skill/flutter_skill.dart';
import 'package:flutter_template/bootstrap.dart';
import 'package:flutter_template/firebase_options.dart';

void main() {
  FlutterSkillBinding.ensureInitialized();

  bootstrap(firebaseOptions: () => DefaultFirebaseOptions.currentPlatform);
}
