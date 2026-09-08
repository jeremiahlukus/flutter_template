// Native configuration that the Dart suite can still verify by reading it.
//
// Deep links and deployment targets are build-time facts, so nothing in the
// widget tests can exercise them. That used to make them unprovable rows in a
// Verification table. Parsing the files is weaker than an on-device run, but it
// is strong enough to catch the failure that actually happens: someone edits
// one platform and forgets the other.
@Tags(['architecture'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The lowest iOS version every current Firebase pod supports.
///
/// Raise this only together with `ios/Podfile` — a pod that needs more than the
/// project offers fails `pod install` with a message that does not name it.
const firebaseMinimumIosVersion = 15.0;

String _read(String path) => File(path).readAsStringSync();

/// Every `android:scheme="..."` value in the manifest.
Set<String> _androidSchemes(String manifest) => RegExp(
  'android:scheme="([^"]+)"',
).allMatches(manifest).map((m) => m.group(1)!).toSet();

/// The `<string>` entries inside the `CFBundleURLSchemes` array.
Set<String> _iosSchemes(String plist) {
  final array = RegExp(
    r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(plist);
  if (array == null) return const {};
  return RegExp(
    '<string>([^<]+)</string>',
  ).allMatches(array.group(1)!).map((m) => m.group(1)!).toSet();
}

void main() {
  group('deep links are declared for both platforms', () {
    late String manifest;
    late String plist;

    setUp(() {
      manifest = _read('android/app/src/main/AndroidManifest.xml');
      plist = _read('ios/Runner/Info.plist');
    });

    test('the custom scheme is declared on Android and iOS alike', () {
      final android = _androidSchemes(manifest)
        ..removeWhere((s) => s == 'https' || s == 'http');
      final ios = _iosSchemes(plist);

      expect(
        android,
        isNotEmpty,
        reason: 'AndroidManifest.xml declares no custom URL scheme',
      );
      expect(
        ios,
        isNotEmpty,
        reason: 'Info.plist declares no CFBundleURLSchemes',
      );
      expect(
        ios,
        equals(android),
        reason:
            'A scheme on one platform only is a link that works on half the '
            'installs. Android has $android, iOS has $ios.',
      );
    });

    test('Android exposes the scheme through a browsable VIEW filter', () {
      // Without both, the link resolves to nothing and Android silently opens
      // the browser instead.
      expect(manifest, contains('android.intent.action.VIEW'));
      expect(manifest, contains('android.intent.category.BROWSABLE'));
    });

    test('the https App Link opts into verification', () {
      // `autoVerify` is what stops the disambiguation dialog appearing.
      expect(
        manifest,
        contains('android:autoVerify="true"'),
        reason: 'The https intent-filter must set android:autoVerify',
      );
    });
  });

  group('platform deployment targets satisfy every Firebase plugin', () {
    test('the iOS Podfile targets at least the Firebase minimum', () {
      final declared = RegExp(
        r"platform :ios, '([\d.]+)'",
      ).firstMatch(_read('ios/Podfile'))?.group(1);

      expect(declared, isNotNull, reason: 'ios/Podfile declares no platform');
      expect(
        double.parse(declared!),
        greaterThanOrEqualTo(firebaseMinimumIosVersion),
        reason:
            'Firebase needs iOS $firebaseMinimumIosVersion or newer; the '
            'Podfile says $declared.',
      );
    });

    test('the Xcode project agrees with the Podfile', () {
      // Disagreement builds locally and fails on a clean machine, which is the
      // worst place to find it.
      final podfile = double.parse(
        RegExp(
          r"platform :ios, '([\d.]+)'",
        ).firstMatch(_read('ios/Podfile'))!.group(1)!,
      );
      final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);')
          .allMatches(_read('ios/Runner.xcodeproj/project.pbxproj'))
          .map((m) => double.parse(m.group(1)!))
          .toSet();

      expect(targets, isNotEmpty, reason: 'No deployment target in pbxproj');
      for (final target in targets) {
        expect(
          target,
          greaterThanOrEqualTo(podfile),
          reason:
              'A build configuration targets iOS $target, below the Podfile '
              'floor of $podfile.',
        );
      }
    });

    test('the Android minSdk tracks the Flutter default', () {
      // Pinning a literal here is how a project drifts below what Firebase
      // needs; `flutter.minSdkVersion` rises with the SDK instead.
      expect(
        _read('android/app/build.gradle.kts'),
        contains('minSdk = flutter.minSdkVersion'),
        reason:
            'A hard-coded minSdk stops tracking the Firebase floor. Delegate '
            'to flutter.minSdkVersion.',
      );
    });
  });
}
