// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/secure_credentials_storage.dart';
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';

final dioProvider = Provider((ref) => Dio());

final flutterSecureStorageProvider = Provider(
  (ref) => const FlutterSecureStorage(),
);

final credentialsStorageProvider = Provider<CredentialsStorage>(
  (ref) => SecureCredentialsStorage(ref.watch(flutterSecureStorageProvider)),
);

final webAppAuthenticatorProvider = Provider(
  (ref) => WebAppAuthenticator(
    ref.watch(credentialsStorageProvider),
    ref.watch(dioProvider),
  ),
);

// rebuild widget after this changes
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(webAppAuthenticatorProvider),
  ),
);
