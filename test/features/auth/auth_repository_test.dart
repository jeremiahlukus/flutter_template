import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late RecordingAnalyticsService analytics;

  setUp(() => analytics = RecordingAnalyticsService());

  AuthRepository repo(MockFirebaseAuth auth) =>
      AuthRepository(auth: auth, analytics: analytics);

  MockFirebaseAuth signedOut() => MockFirebaseAuth();

  MockFirebaseAuth signedIn([MockUser? user]) =>
      MockFirebaseAuth(mockUser: user ?? testUser(), signedIn: true);

  /// Arms [auth] so the next call to [method] throws [code].
  ///
  /// `firebase_auth_mocks` routes every method through `mock_exceptions`, which
  /// is how the failure paths below get exercised without a live backend.
  MockFirebaseAuth failing(Symbol method, String code) {
    final auth = MockFirebaseAuth();
    whenCalling(
      Invocation.method(method, null, const {}),
    ).on(auth).thenThrow(FirebaseAuthException(code: code));
    return auth;
  }

  group('AuthFailure', () {
    test('maps a known Firebase code to friendly copy', () {
      final failure = AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'wrong-password'),
      );

      expect(failure.code, 'wrong-password');
      expect(failure.message, 'Incorrect email or password.');
    });

    test('maps invalid-credential to the same copy as wrong-password', () {
      // Firebase returns invalid-credential on newer SDKs; users should not see
      // two different sentences for the same mistake.
      expect(
        AuthFailure.fromFirebase(
          FirebaseAuthException(code: 'invalid-credential'),
        ).message,
        AuthFailure.fromFirebase(
          FirebaseAuthException(code: 'wrong-password'),
        ).message,
      );
    });

    test('falls back to the Firebase message for an unmapped code', () {
      final failure = AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'odd-code', message: 'Raw detail'),
      );

      expect(failure.message, 'Raw detail');
    });

    test('falls back to generic copy when there is no message either', () {
      final failure = AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'odd-code'),
      );

      expect(failure.message, 'Authentication failed.');
    });

    test('toString names the code and message', () {
      const failure = AuthFailure('c', 'm');
      expect(failure.toString(), contains('c'));
      expect(failure.toString(), contains('m'));
    });
  });

  group('currentUser', () {
    test('is null when signed out', () {
      expect(repo(signedOut()).currentUser, isNull);
      expect(repo(signedOut()).isSignedIn, isFalse);
    });

    test('adapts the Firebase user when signed in', () {
      final user = repo(signedIn()).currentUser;

      expect(user!.id, 'user-1');
      expect(user.email, 'tester@example.com');
      expect(repo(signedIn()).isSignedIn, isTrue);
    });
  });

  group('authStateChanges', () {
    test('emits null while signed out', () {
      expect(repo(signedOut()).authStateChanges(), emits(isNull));
    });

    test('emits the user when signed in', () {
      expect(
        repo(signedIn()).authStateChanges(),
        emits(isA<Object>().having((u) => (u as dynamic).id, 'id', 'user-1')),
      );
    });

    test('the subscription can be cancelled', () async {
      // Regression guard: an `async*` implementation deadlocked here, because a
      // generator suspended in `await for` over a never-closing broadcast
      // stream cannot be cancelled. A hung cancel leaks the router's listener.
      final sub = repo(signedIn()).authStateChanges().listen((_) {});
      await pumpEventQueue();

      await expectLater(
        sub.cancel().timeout(const Duration(seconds: 2)),
        completes,
      );
    });

    test('does not re-emit an unchanged user', () async {
      final auth = signedIn();
      final subject = repo(auth);
      final seen = <String?>[];
      final sub = subject.authStateChanges().listen((u) => seen.add(u?.id));

      await pumpEventQueue();
      await sub.cancel();

      // The seeded value and the mock's own replay are the same user; the
      // consumer should see it once.
      expect(seen, ['user-1']);
    });

    test('emits null after a sign-out', () async {
      final auth = signedIn();
      final subject = repo(auth);
      final seen = <String?>[];
      final sub = subject.authStateChanges().listen((u) => seen.add(u?.id));

      await pumpEventQueue();
      await subject.signOut();
      await pumpEventQueue();
      await sub.cancel();

      expect(seen, ['user-1', null]);
    });
  });

  group('signInWithEmail', () {
    test('returns the user and records analytics', () async {
      final subject = repo(signedOut());

      final user = await subject.signInWithEmail(
        email: 'a@b.co',
        password: 'password',
      );

      expect(user.id, isNotEmpty);
      expect(analytics.eventNames, contains('login'));
      expect(analytics.userId, user.id);
    });

    test('trims whitespace from the email', () async {
      final auth = signedOut();
      await repo(auth).signInWithEmail(email: '  a@b.co  ', password: 'pw');

      expect(auth.currentUser, isNotNull);
    });

    test('translates a Firebase exception into an AuthFailure', () async {
      final auth = failing(#signInWithEmailAndPassword, 'wrong-password');

      await expectLater(
        repo(auth).signInWithEmail(email: 'a@b.co', password: 'bad'),
        throwsA(
          isA<AuthFailure>()
              .having((e) => e.code, 'code', 'wrong-password')
              .having(
                (e) => e.message,
                'message',
                'Incorrect email or password.',
              ),
        ),
      );
    });

    test('does not set a user id when sign-in fails', () async {
      final auth = failing(#signInWithEmailAndPassword, 'user-not-found');

      await expectLater(
        repo(auth).signInWithEmail(email: 'a@b.co', password: 'x'),
        throwsA(isA<AuthFailure>()),
      );
      expect(analytics.userId, isNull);
    });
  });

  group('createAccount', () {
    test('returns the user and records a sign_up', () async {
      final user = await repo(signedOut()).createAccount(
        email: 'new@b.co',
        password: 'password',
      );

      expect(user.id, isNotEmpty);
      expect(analytics.eventNames, contains('sign_up'));
      expect(analytics.userId, user.id);
    });

    test('translates email-already-in-use', () async {
      final auth = failing(
        #createUserWithEmailAndPassword,
        'email-already-in-use',
      );

      await expectLater(
        repo(auth).createAccount(email: 'a@b.co', password: 'pw'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'An account already exists for that email.',
          ),
        ),
      );
    });
  });

  group('signInAnonymously', () {
    test('signs in and records an anonymous login', () async {
      final user = await repo(signedOut()).signInAnonymously();

      expect(user.id, isNotEmpty);
      expect(
        analytics.events.firstWhere((e) => e.name == 'login').parameters,
        {'method': 'anonymous'},
      );
    });
  });

  group('signOut', () {
    test('clears the user and the analytics id', () async {
      final auth = signedIn();
      final subject = repo(auth);
      await subject.signInWithEmail(email: 'a@b.co', password: 'pw');

      await subject.signOut();

      expect(auth.currentUser, isNull);
      expect(analytics.eventNames, contains('sign_out'));
      expect(analytics.userId, isNull);
    });
  });

  group('sendPasswordResetEmail', () {
    test('records the request', () async {
      await repo(signedOut()).sendPasswordResetEmail('  a@b.co ');
      expect(analytics.eventNames, contains('password_reset_requested'));
    });
  });

  group('sendEmailVerification', () {
    test('records the send when signed in', () async {
      await repo(signedIn()).sendEmailVerification();
      expect(analytics.eventNames, contains('email_verification_sent'));
    });

    test('is a no-op when signed out', () async {
      await repo(signedOut()).sendEmailVerification();
      expect(analytics.eventNames, contains('email_verification_sent'));
    });
  });

  group('updateDisplayName', () {
    test('applies the trimmed name', () async {
      final user = await repo(signedIn()).updateDisplayName('  Grace  ');

      expect(user.displayName, 'Grace');
      expect(analytics.eventNames, contains('profile_updated'));
    });

    test('throws when signed out', () async {
      await expectLater(
        repo(signedOut()).updateDisplayName('X'),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'no-current-user'),
        ),
      );
    });
  });

  group('updatePhotoUrl', () {
    test('applies the url', () async {
      final user = await repo(
        signedIn(),
      ).updatePhotoUrl('https://example.com/a.png');

      expect(user.photoUrl, 'https://example.com/a.png');
      expect(
        analytics.events.last.parameters,
        {'field': 'photo_url'},
      );
    });

    test('throws when signed out', () async {
      await expectLater(
        repo(signedOut()).updatePhotoUrl('https://x/y.png'),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'no-current-user'),
        ),
      );
    });
  });

  group('deleteAccount', () {
    test('removes the user and clears analytics', () async {
      final auth = signedIn();
      await repo(auth).deleteAccount();

      expect(analytics.eventNames, contains('account_deleted'));
      expect(analytics.userId, isNull);
    });

    test('throws when signed out', () async {
      await expectLater(
        repo(signedOut()).deleteAccount(),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'no-current-user'),
        ),
      );
    });
  });
}
