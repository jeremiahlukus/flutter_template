import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('authStateProvider', () {
    test('resolves to null when signed out', () async {
      final harness = TestHarness.create();

      expect(await harness.container.read(authStateProvider.future), isNull);
    });

    test('resolves to the user when signed in', () async {
      final harness = TestHarness.create(user: testUser());

      final user = await harness.container.read(authStateProvider.future);
      expect(user!.id, 'user-1');
    });
  });

  group('currentUserProvider', () {
    test('is null before the stream resolves', () {
      final harness = TestHarness.create(user: testUser());
      expect(harness.read(currentUserProvider), isNull);
    });

    test('exposes the user once resolved', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);

      expect(harness.read(currentUserProvider)!.email, 'tester@example.com');
    });

    test('is null when signed out', () async {
      final harness = TestHarness.create();
      await harness.container.read(authStateProvider.future);

      expect(harness.read(currentUserProvider), isNull);
    });
  });

  group('isSignedInProvider', () {
    test('is false when signed out', () async {
      final harness = TestHarness.create();
      await harness.container.read(authStateProvider.future);

      expect(harness.read(isSignedInProvider), isFalse);
    });

    test('is true when signed in', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);

      expect(harness.read(isSignedInProvider), isTrue);
    });
  });

  group('authRepositoryProvider', () {
    test('builds a repository wired to the overridden auth instance', () {
      final harness = TestHarness.create(user: testUser());

      expect(harness.read(authRepositoryProvider).currentUser!.id, 'user-1');
    });
  });

  group('AuthController', () {
    test('starts in a data state', () {
      final harness = TestHarness.create();

      expect(harness.read(authControllerProvider), isA<AsyncData<void>>());
    });

    test('signIn returns true and leaves a data state', () async {
      final harness = TestHarness.create();
      final controller = harness.read(authControllerProvider.notifier);

      final ok = await controller.signIn(email: 'a@b.co', password: 'pw');

      expect(ok, isTrue);
      expect(harness.read(authControllerProvider), isA<AsyncData<void>>());
    });

    test('signIn surfaces a failure as an error state', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final harness = TestHarness.create(mockAuth: auth);
      final controller = harness.read(authControllerProvider.notifier);

      final ok = await controller.signIn(email: 'a@b.co', password: 'bad');

      expect(ok, isFalse);
      final state = harness.read(authControllerProvider);
      expect(state, isA<AsyncError<void>>());
      expect((state as AsyncError<void>).error, isA<AuthFailure>());
    });

    test('signUp creates an account', () async {
      final harness = TestHarness.create();

      final ok = await harness
          .read(authControllerProvider.notifier)
          .signUp(email: 'new@b.co', password: 'password');

      expect(ok, isTrue);
      expect(harness.analytics.eventNames, contains('sign_up'));
    });

    test('signInAnonymously succeeds', () async {
      final harness = TestHarness.create();

      expect(
        await harness.read(authControllerProvider.notifier).signInAnonymously(),
        isTrue,
      );
    });

    test('signOut succeeds', () async {
      final harness = TestHarness.create(user: testUser());

      expect(
        await harness.read(authControllerProvider.notifier).signOut(),
        isTrue,
      );
      expect(harness.auth.currentUser, isNull);
    });

    test('sendPasswordReset succeeds', () async {
      final harness = TestHarness.create();

      expect(
        await harness
            .read(authControllerProvider.notifier)
            .sendPasswordReset('a@b.co'),
        isTrue,
      );
    });

    test('updateDisplayName succeeds when signed in', () async {
      final harness = TestHarness.create(user: testUser());

      expect(
        await harness
            .read(authControllerProvider.notifier)
            .updateDisplayName('Grace'),
        isTrue,
      );
      expect(harness.auth.currentUser!.displayName, 'Grace');
    });

    test('updateDisplayName reports failure when signed out', () async {
      final harness = TestHarness.create();

      expect(
        await harness
            .read(authControllerProvider.notifier)
            .updateDisplayName('Grace'),
        isFalse,
      );
      expect(harness.read(authControllerProvider), isA<AsyncError<void>>());
    });

    test('updatePhotoUrl succeeds when signed in', () async {
      final harness = TestHarness.create(user: testUser());

      expect(
        await harness
            .read(authControllerProvider.notifier)
            .updatePhotoUrl('https://x/y.png'),
        isTrue,
      );
    });

    test('deleteAccount reports failure when signed out', () async {
      final harness = TestHarness.create();

      expect(
        await harness.read(authControllerProvider.notifier).deleteAccount(),
        isFalse,
      );
    });

    test('deleteAccount succeeds when signed in', () async {
      final harness = TestHarness.create(user: testUser());

      expect(
        await harness.read(authControllerProvider.notifier).deleteAccount(),
        isTrue,
      );
    });

    test('a recovered call clears a previous error state', () async {
      final harness = TestHarness.create();
      final controller = harness.read(authControllerProvider.notifier);

      await controller.updateDisplayName('X');
      expect(harness.read(authControllerProvider), isA<AsyncError<void>>());

      await controller.signIn(email: 'a@b.co', password: 'pw');
      expect(harness.read(authControllerProvider), isA<AsyncData<void>>());
    });
  });

  group('AppUser identity across the provider graph', () {
    test('the same Firebase user yields an equal AppUser', () async {
      final harness = TestHarness.create(user: testUser());
      await harness.container.read(authStateProvider.future);

      final fromProvider = harness.read(currentUserProvider);
      final fromRepo = harness.read(authRepositoryProvider).currentUser;

      expect(fromProvider, fromRepo);
      expect(fromProvider, isA<AppUser>());
    });
  });
}
