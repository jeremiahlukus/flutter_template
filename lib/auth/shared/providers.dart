// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/secure_credentials_storage.dart';
import 'package:flutter_template/auth/infrastructure/oauth2_interceptor.dart';
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';

// Only for the auth feature, everything else uses oAuth2InterceptorProvider which adds the correct headers
final dioForAuthProvider = Provider((ref) => Dio());

final flutterSecureStorageProvider = Provider(
  (ref) => const FlutterSecureStorage(),
);

final credentialsStorageProvider = Provider<CredentialsStorage>(
  (ref) => SecureCredentialsStorage(ref.watch(flutterSecureStorageProvider)),
);

final oAuth2InterceptorProvider = Provider(
  (ref) => OAuth2Interceptor(
    ref.watch(webAppAuthenticatorProvider),
    // don't want to watch the state just the notifier itself
    ref.watch(authNotifierProvider.notifier),
    ref.watch(dioForAuthProvider),
  ),
);

final webAppAuthenticatorProvider = Provider(
  (ref) => WebAppAuthenticator(
    ref.watch(credentialsStorageProvider),
    ref.watch(dioForAuthProvider),
  ),
);

// rebuild widget after this changes
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(webAppAuthenticatorProvider),
  ),
);
