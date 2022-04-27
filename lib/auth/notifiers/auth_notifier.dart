// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/auth/domain/auth_failure.dart';
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';

part 'auth_notifier.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState.initial() = _Initial;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.failure(AuthFailure failure) = _Failure;
}

typedef AuthUriCallback = Future<Uri> Function(Uri authorizationUrl);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authenticator) : super(const AuthState.initial());

  final WebAppAuthenticator _authenticator;

  Future<void> checkAndUpdateAuthStatus() async {
    state = (await _authenticator.isSignedIn()) ? const AuthState.authenticated() : const AuthState.unauthenticated();
  }

  Future<void> signIn(AuthUriCallback authorizationCallback) async {
    final redirectUrl = await authorizationCallback(_authenticator.getAuthorizationUrl());
    final failureOrSuccess = await _authenticator.handleAuthorizationResponse(
      redirectUrl.queryParameters,
    );
    state = failureOrSuccess.fold(
      AuthState.failure,
      (r) => const AuthState.authenticated(),
    );
  }

  Future<void> signOut() async {
    final failureOrSuccess = await _authenticator.signOut();
    state = failureOrSuccess.fold(
      AuthState.failure,
      (r) => const AuthState.unauthenticated(),
    );
  }
}
