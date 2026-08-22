import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` and `ProviderListenable` are not in the main barrel file.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_template/src/app/app.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_template/src/core/errors/error_reporter.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart'
    show NotesRepository;
import 'package:flutter_template/src/features/onboarding/onboarding_providers.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';
import 'package:flutter_template/src/features/storage/image_source_service.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/l10n/l10n_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Re-exported so tests can seed a preference without a second import.
export 'package:flutter_template/src/features/settings/setting_keys.dart';

/// Everything a test needs to drive the app with no Firebase project.
///
/// Bundling the fakes in one object (rather than returning a bare container)
/// means a test can both *drive* the app and *assert* on what the fakes
/// received, without re-reading providers to get at them.
class TestHarness {
  TestHarness._({
    required this.container,
    required this.auth,
    required this.firestore,
    required this.database,
    required this.analytics,
    required this.storage,
    required this.connectivity,
    required this.errorReporter,
    required this.imageSource,
    required this.push,
  });

  /// Builds a harness. Pass [user] to start signed in.
  ///
  /// `signedIn` on `MockFirebaseAuth` is what makes `authStateChanges()` emit
  /// straight away — without it the router sits in its loading state forever.
  ///
  /// Anything the harness already overrides has a named parameter here —
  /// `mockAuth`, `config`, `packageInfo`, `database`. Supplying one of those
  /// through [extraOverrides] instead would override the same provider twice,
  /// which Riverpod rejects.
  ///
  /// Pass [database] to share one across harnesses, which is how a test models
  /// an app restart: same on-disk state, brand-new provider container.
  factory TestHarness.create({
    MockUser? user,
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? firestore,
    AppDatabase? database,
    AppEnvironment environment = AppEnvironment.prod,
    AppConfig? config,
    NetworkStatus network = NetworkStatus.online,
    PackageInfo? packageInfo,
    bool onboardingCompleted = true,
    List<Override> extraOverrides = const [],
  }) {
    // Pass `mockAuth` to supply a pre-armed instance; overriding
    // `firebaseAuthProvider` via `extraOverrides` would be a double override,
    // which Riverpod rejects.
    final auth =
        mockAuth ?? MockFirebaseAuth(mockUser: user, signedIn: user != null);
    final store = firestore ?? FakeFirebaseFirestore();
    final db = database ?? AppDatabase.memory();
    final analytics = RecordingAnalyticsService();
    final storage = InMemoryStorageRepository();
    final connectivity = FakeConnectivityService(network);
    final errorReporter = RecordingErrorReporter();
    final imageSource = FakeImageSourceService();
    final push = FakePushService();

    // Defaults to `prod` so behaviour is predictable: the dev config disables
    // analytics and crash reporting, which would silently neuter assertions.
    final resolvedConfig = config ?? AppConfig.forEnvironment(environment);

    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(store),
        appDatabaseProvider.overrideWithValue(db),
        analyticsServiceProvider.overrideWithValue(analytics),
        storageRepositoryProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
        imageSourceServiceProvider.overrideWithValue(imageSource),
        pushServiceProvider.overrideWithValue(push),
        errorReporterProvider.overrideWithValue(errorReporter),
        appConfigProvider.overrideWithValue(resolvedConfig),
        // `PackageInfo.fromPlatform` needs a platform channel.
        packageInfoProvider.overrideWith(
          (ref) async => packageInfo ?? testPackageInfo(),
        ),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.dispose);
    addTearDown(push.dispose);
    // Only close a database this harness owns; a shared one is the caller's.
    if (database == null) addTearDown(db.close);

    // Most tests are about a screen, not the intro, so onboarding is marked
    // complete by default. Pass `onboardingCompleted: false` to test the gate.
    if (onboardingCompleted) {
      db.writeSetting(SettingKeys.onboardingCompleted, 'true');
    }

    // Riverpod 3 auto-disposes providers with no listeners, and a disposed
    // StreamProvider never emits. In the real app the router always listens to
    // auth, so hold a subscription here to model that.
    container.listen(authStateProvider, (_, _) {}, fireImmediately: true);

    return TestHarness._(
      container: container,
      auth: auth,
      firestore: store,
      database: db,
      analytics: analytics,
      storage: storage,
      connectivity: connectivity,
      errorReporter: errorReporter,
      imageSource: imageSource,
      push: push,
    );
  }

  final ProviderContainer container;
  final MockFirebaseAuth auth;
  final FakeFirebaseFirestore firestore;
  final AppDatabase database;
  final RecordingAnalyticsService analytics;
  final InMemoryStorageRepository storage;
  final FakeConnectivityService connectivity;
  final RecordingErrorReporter errorReporter;
  final FakeImageSourceService imageSource;
  final FakePushService push;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Holds a subscription to [provider] for the rest of the test.
  ///
  /// Needed because Riverpod 3 auto-disposes providers the moment they have no
  /// listeners, which makes an un-listened async provider hang forever.
  void keepAlive(ProviderListenable<Object?> provider) {
    container.listen(provider, (_, _) {}, fireImmediately: true);
  }

  /// Pumps the real [TemplateApp] against this harness's fakes.
  ///
  /// Resolves the async providers the first frame depends on *before* pumping.
  /// Without this, the notes screen renders a `CircularProgressIndicator`, and a
  /// never-ending animation makes `pumpAndSettle` time out rather than settle.
  Future<void> pumpApp(WidgetTester tester) async {
    await settleProviders();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Awaits every async provider the first frame reads.
  Future<void> settleProviders() async {
    keepAlive(notesProvider);
    keepAlive(themeModeControllerProvider);
    keepAlive(networkStatusProvider);

    await container.read(authStateProvider.future);
    await container.read(themeModeControllerProvider.future);
    await container.read(brandControllerProvider.future);
    await container.read(localeControllerProvider.future);
    await container.read(onboardingControllerProvider.future);
    await container.read(notesProvider.future);
  }

  /// Pumps an arbitrary [widget] inside a localised MaterialApp, for screens
  /// that do not need the router.
  ///
  /// The localisation delegates are not optional — any widget reading
  /// `context.l10n` throws without them.
  /// Pass `settle: false` for a screen that shows a spinner — a perpetual
  /// animation means `pumpAndSettle` times out instead of settling.
  Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // Matches TemplateApp, and keeps the debug ribbon out of
          // `find.byType(Banner)` assertions.
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocales.supported,
          home: widget,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
}

/// A signed-in test user with sensible, assertable values.
/// Note the non-http [photoUrl]: `MockUser` substitutes a live imgur URL when
/// `photoURL` is null, and a `NetworkImage` in a widget test fails the test with
/// an HTTP 400. A `memory://` URL exercises the same code path offline.
MockUser testUser({
  String uid = 'user-1',
  String email = 'tester@example.com',
  String? displayName = 'Ada Lovelace',
  String photoUrl = 'memory://users/user-1/avatar.jpg',
  bool isEmailVerified = true,
  bool isAnonymous = false,
}) => MockUser(
  uid: uid,
  email: email,
  displayName: displayName,
  photoURL: photoUrl,
  isEmailVerified: isEmailVerified,
  isAnonymous: isAnonymous,
);

/// An in-memory database owned by the test, for sharing across harnesses.
///
/// Use this to model an app restart: same stored state, new provider container.
AppDatabase harnessDatabase() {
  final db = AppDatabase.memory();
  addTearDown(db.close);
  return db;
}

/// Stand-in for the platform bundle info.
PackageInfo testPackageInfo({
  String version = '1.2.3',
  String buildNumber = '45',
}) => PackageInfo(
  appName: 'flutter_template',
  packageName: 'com.example.flutter_template',
  version: version,
  buildNumber: buildNumber,
);

/// A note with a fixed timestamp, so equality assertions are stable.
Note testNote({
  String id = 'note-1',
  String title = 'First note',
  String body = 'Body text',
  DateTime? updatedAt,
  bool pendingSync = false,
}) => Note(
  id: id,
  title: title,
  body: body,
  updatedAt: updatedAt ?? DateTime.utc(2026, 1, 2, 3, 4, 5),
  pendingSync: pendingSync,
);

/// Seeds Firestore at the path [NotesRepository] reads from.
Future<void> seedRemoteNotes(
  FakeFirebaseFirestore firestore,
  String userId,
  List<Note> notes,
) async {
  final collection = firestore
      .collection('users')
      .doc(userId)
      .collection('notes');
  for (final note in notes) {
    await collection.doc(note.id).set(note.toFirestore());
  }
}

/// Reads every remote note back, for round-trip assertions.
Future<List<Note>> readRemoteNotes(
  FakeFirebaseFirestore firestore,
  String userId,
) async {
  final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('notes')
      .get();
  return snapshot.docs.map((d) => Note.fromFirestore(d.id, d.data())).toList();
}

/// Matcher for a Firestore [Timestamp] at the same instant as [expected].
///
/// Compares in UTC because `Timestamp.toDate()` returns local time.
Matcher timestampOf(DateTime expected) => predicate<Object?>(
  (v) => v is Timestamp && v.toDate().toUtc() == expected.toUtc(),
  'a Timestamp at $expected',
);
