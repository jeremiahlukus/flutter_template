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
  // Indicators off. `flutter_skill`'s particle painter calls
  // `Color.withOpacity(0.8 * (1 - progress))`, which goes negative once
  // `progress` passes 1 and trips an assertion — so every driven tap prints an
  // "Uncaught framework error" box that looks like an app crash and buries the
  // real failures you are reading the log for. Verified against 0.9.36.
  //
  // Flip to `true` (or call `ext.flutter.flutter_skill.enableIndicators`) if you
  // are watching a flow by eye and want the tap visualisation.
  FlutterSkillBinding.ensureInitialized(autoEnableIndicators: false);

  bootstrap(firebaseOptions: () => DefaultFirebaseOptions.currentPlatform);
}
