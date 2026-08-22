import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// These providers are the app's only contact point with the Firebase SDK
/// singletons. The tests below prove two things: the default bodies really do
/// resolve to `.instance`, and every one of them can be replaced wholesale —
/// which is what the rest of the suite depends on.
void main() {
  test('firebaseAuthProvider resolves to the SDK singleton', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(firebaseAuthProvider), same(FirebaseAuth.instance));
  });

  test('firestoreProvider resolves to the SDK singleton', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(firestoreProvider),
      same(FirebaseFirestore.instance),
    );
  });

  // `FirebaseStorage.instance` is deliberately not exercised: unlike Auth,
  // Firestore, and Analytics, it needs its own platform channel registered, and
  // stubbing the whole Storage plugin to prove a one-line provider body returns
  // `.instance` is not worth the fixture. `FirebaseStorageRepository` itself is
  // covered directly in
  // test/features/storage/firebase_storage_repository_test.dart.
  test('firebaseStorageProvider can be overridden', () {
    final replacement = _StubStorage();
    final container = ProviderContainer(
      overrides: [firebaseStorageProvider.overrideWithValue(replacement)],
    );
    addTearDown(container.dispose);

    expect(container.read(firebaseStorageProvider), same(replacement));
    expect(
      container.read(storageRepositoryProvider),
      isA<FirebaseStorageRepository>(),
    );
  });

  test('firebaseAnalyticsProvider resolves to the SDK singleton', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(firebaseAnalyticsProvider),
      same(FirebaseAnalytics.instance),
    );
  });

  group('analyticsServiceProvider', () {
    test('is a no-op where the environment disables analytics', () {
      // Dev traffic must never reach production analytics.
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.dev),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(analyticsServiceProvider),
        isA<NoopAnalyticsService>(),
      );
    });

    test('wraps the Firebase implementation in a consent gate elsewhere', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.prod),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(analyticsServiceProvider),
        isA<ConsentGatedAnalyticsService>(),
      );
    });
  });

  test('every Firebase seam is replaceable', () {
    // The suite's whole strategy rests on this: nothing outside
    // firebase_providers.dart touches a Firebase singleton directly.
    final container = ProviderContainer(
      overrides: [
        firebaseStorageProvider.overrideWithValue(_StubStorage()),
        analyticsServiceProvider.overrideWithValue(RecordingAnalyticsService()),
        storageRepositoryProvider.overrideWithValue(
          InMemoryStorageRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(analyticsServiceProvider),
      isA<RecordingAnalyticsService>(),
    );
    expect(
      container.read(storageRepositoryProvider),
      isA<InMemoryStorageRepository>(),
    );
  });
}

/// Minimal stand-in; nothing calls through it.
class _StubStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not used in tests');
}
