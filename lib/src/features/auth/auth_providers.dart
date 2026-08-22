import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';
import 'package:flutter_template/src/features/auth/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);

/// The single source of truth for "who is signed in".
///
/// The router, the app bar, and every feature read this rather than asking
/// Firebase, so a sign-out propagates everywhere in one frame.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Synchronous view of [authStateProvider]; null while loading or signed out.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
);

/// Drives the sign-in / sign-up forms.
///
/// Holds the in-flight and error state so screens stay stateless widgets and the
/// same logic is exercised by tests without pumping any UI.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn({required String email, required String password}) =>
      _guard(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> signUp({required String email, required String password}) =>
      _guard(() => _repo.createAccount(email: email, password: password));

  Future<bool> signInAnonymously() => _guard(_repo.signInAnonymously);

  Future<bool> signOut() => _guard(_repo.signOut);

  Future<bool> sendPasswordReset(String email) =>
      _guard(() => _repo.sendPasswordResetEmail(email));

  Future<bool> updateDisplayName(String name) =>
      _guard(() => _repo.updateDisplayName(name));

  Future<bool> updatePhotoUrl(String url) =>
      _guard(() => _repo.updatePhotoUrl(url));

  Future<bool> deleteAccount() => _guard(_repo.deleteAccount);

  /// Runs [action], surfacing progress via [state]. Returns true on success.
  Future<bool> _guard(Future<void> Function() action) async {
    state = const AsyncValue<void>.loading();
    try {
      await action();
      state = const AsyncValue<void>.data(null);
      return true;
    } on AuthFailure catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
