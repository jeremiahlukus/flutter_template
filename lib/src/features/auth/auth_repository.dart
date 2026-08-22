import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';

/// Raised for every auth failure the UI is expected to render.
///
/// Firebase error codes are mapped to human sentences here, once, rather than in
/// each screen's catch block.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  factory AuthFailure.fromFirebase(FirebaseAuthException e) => AuthFailure(
    e.code,
    _messages[e.code] ?? e.message ?? 'Authentication failed.',
  );

  final String code;
  final String message;

  static const _messages = <String, String>{
    'invalid-email': 'That email address is not valid.',
    'user-disabled': 'This account has been disabled.',
    'user-not-found': 'No account found for that email.',
    'wrong-password': 'Incorrect email or password.',
    'invalid-credential': 'Incorrect email or password.',
    'email-already-in-use': 'An account already exists for that email.',
    'weak-password': 'Choose a password with at least 6 characters.',
    'requires-recent-login': 'Please sign in again to complete this change.',
    'too-many-requests': 'Too many attempts. Try again in a few minutes.',
    'network-request-failed': 'Network unavailable. Check your connection.',
    'operation-not-allowed': 'That sign-in method is not enabled.',
  };

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// All authentication behaviour, expressed in the app's own vocabulary.
class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics;

  final FirebaseAuth _auth;
  final AnalyticsService _analytics;

  /// Emits the current user immediately, then again on every change.
  ///
  /// `FirebaseAuth.authStateChanges()` is a *broadcast* stream: a subscriber
  /// that arrives after the SDK has already settled receives nothing until the
  /// next transition. Seeding with [currentUser] closes that startup race — the
  /// window where the router would otherwise sit in its loading state forever.
  ///
  /// Consecutive duplicates are filtered, so the seed value costs nothing when
  /// the underlying stream does replay the current state.
  ///
  /// Built with [Stream.multi] rather than an `async*` generator on purpose: a
  /// generator suspended in `await for` over a broadcast stream that never
  /// closes cannot be cancelled — `cancel()` hangs forever and the subscription
  /// leaks. `Stream.multi` gives an explicit `onCancel` that forwards straight
  /// to the upstream subscription.
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      var previous = currentUser;
      controller.add(previous);

      final subscription = _auth.authStateChanges().listen(
        (user) {
          final next = user == null ? null : AppUser.fromFirebase(user);
          if (next != previous) {
            previous = next;
            controller.add(next);
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );

      controller.onCancel = subscription.cancel;
    });
  }

  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUser.fromFirebase(user);
  }

  bool get isSignedIn => _auth.currentUser != null;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => _run('sign_in', () async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _requireUser(cred.user);
    await _analytics.logLogin('password');
    await _analytics.setUserId(user.id);
    return user;
  });

  Future<AppUser> createAccount({
    required String email,
    required String password,
  }) => _run('sign_up', () async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _requireUser(cred.user);
    await _analytics.logSignUp('password');
    await _analytics.setUserId(user.id);
    return user;
  });

  Future<AppUser> signInAnonymously() => _run('sign_in_anonymous', () async {
    final cred = await _auth.signInAnonymously();
    final user = _requireUser(cred.user);
    await _analytics.logLogin('anonymous');
    await _analytics.setUserId(user.id);
    return user;
  });

  Future<void> signOut() => _run('sign_out', () async {
    await _auth.signOut();
    await _analytics.logEvent('sign_out');
    await _analytics.setUserId(null);
  });

  Future<void> sendPasswordResetEmail(String email) =>
      _run('password_reset', () async {
        await _auth.sendPasswordResetEmail(email: email.trim());
        await _analytics.logEvent('password_reset_requested');
      });

  Future<void> sendEmailVerification() => _run('email_verification', () async {
    await _auth.currentUser?.sendEmailVerification();
    await _analytics.logEvent('email_verification_sent');
  });

  Future<AppUser> updateDisplayName(String name) =>
      _run('update_display_name', () async {
        final user = _auth.currentUser;
        if (user == null) {
          throw const AuthFailure('no-current-user', 'You are not signed in.');
        }
        await user.updateDisplayName(name.trim());
        await user.reload();
        await _analytics.logEvent(
          'profile_updated',
          parameters: {
            'field': 'display_name',
          },
        );
        return AppUser.fromFirebase(_auth.currentUser ?? user);
      });

  Future<AppUser> updatePhotoUrl(String url) => _run('update_photo', () async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('no-current-user', 'You are not signed in.');
    }
    await user.updatePhotoURL(url);
    await user.reload();
    await _analytics.logEvent(
      'profile_updated',
      parameters: {
        'field': 'photo_url',
      },
    );
    return AppUser.fromFirebase(_auth.currentUser ?? user);
  });

  Future<void> deleteAccount() => _run('delete_account', () async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('no-current-user', 'You are not signed in.');
    }
    await user.delete();
    await _analytics.logEvent('account_deleted');
    await _analytics.setUserId(null);
  });

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw const AuthFailure(
        'null-user',
        'Sign-in succeeded but no user was returned.',
      );
    }
    return AppUser.fromFirebase(user);
  }

  /// Normalises every Firebase throw into an [AuthFailure] and logs it.
  Future<T> _run<T>(String label, Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.w('Auth "$label" failed: ${e.code}');
      throw AuthFailure.fromFirebase(e);
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'Auth "$label" failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      throw const AuthFailure(
        'unknown',
        'Something went wrong. Please try again.',
      );
    }
  }
}
