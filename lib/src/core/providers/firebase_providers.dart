import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';

/// Local emulator ports. Must match `firebase.json`.
///
/// Duplicated from that file rather than parsed out of it: a mismatch surfaces
/// immediately as a connection refused, and a JSON parse at startup is a worse
/// failure mode than a stale constant.
abstract final class EmulatorPorts {
  static const host = 'localhost';
  static const auth = 9099;
  static const firestore = 8080;
  static const storage = 9199;
}

/// Seams for every Firebase SDK singleton the app touches.
///
/// Nothing outside this file may call `FirebaseAuth.instance` (or friends)
/// directly. Routing every access through a provider is what lets the test
/// suite swap in `MockFirebaseAuth` / `FakeFirebaseFirestore` wholesale — and it
/// is also the one place emulator redirection can live.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final auth = FirebaseAuth.instance;
  if (ref.watch(appConfigProvider).useEmulators) {
    auth.useAuthEmulator(EmulatorPorts.host, EmulatorPorts.auth);
    AppLogger.instance.i('Auth → emulator');
  }
  return auth;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  if (ref.watch(appConfigProvider).useEmulators) {
    firestore.useFirestoreEmulator(
      EmulatorPorts.host,
      EmulatorPorts.firestore,
    );
    AppLogger.instance.i('Firestore → emulator');
  }
  return firestore;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  final storage = FirebaseStorage.instance;
  if (ref.watch(appConfigProvider).useEmulators) {
    storage.useStorageEmulator(EmulatorPorts.host, EmulatorPorts.storage);
    AppLogger.instance.i('Storage → emulator');
  }
  return storage;
});

/// Not redirected: Analytics has no emulator, and a non-production
/// `AppConfig.analyticsEnabled` already suppresses collection entirely.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);
