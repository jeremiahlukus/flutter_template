// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:oauth2/oauth2.dart';

// Project imports:
import 'package:flutter_template/auth/domain/auth_failure.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:flutter_template/core/infrastructure/dio_extensions.dart';
import 'package:flutter_template/core/presentation/bootstrap.dart';

class WebAppAuthenticator {
  WebAppAuthenticator(this._credentialsStorage, this._dio);

  final CredentialsStorage _credentialsStorage;
  final Dio _dio;
  static final localAuthorizationEndpoint = Platform.isAndroid
      ? Uri.parse('http://10.0.2.2:3000/users/sign_in')
      : Uri.parse('http://127.0.0.1:3000/users/sign_in');
  static final authorizationEndpoint = Uri.parse('http://someUrl/users/sign_in');
  static final revocationEndpoint = Uri.parse('http://127.0.0.1:3000/api/v1/auth');
  static final redirectUrl = Uri.parse('http://127.0.0.1:3000/callback');

  Future<Credentials?> getSignedInCredentials() async {
    try {
      final storedCredentials = await _credentialsStorage.read();
      // if (storedCredentials != null) {
      //   if (storedCredentials.canRefresh && storedCredentials.isExpired) {
      //     final failureOrCredentials = await refresh(storedCredentials);
      //     // if failure from refresh return null else return creds.
      //     failureOrCredentials.fold((l) => null, (r) => r);
      //   }
      // }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedIn() => getSignedInCredentials().then((creds) => creds != null);

  // unit == void
  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
    Map<String, String> queryParams,
  ) async {
    try {
      if (queryParams['state'] != null && queryParams['state']!.isNotEmpty) {
        final credentials = Credentials(queryParams['state'].toString());
        await _credentialsStorage.save(credentials);
        return right(unit);
      } else {
        return left(const AuthFailure.server('Query Params are empty'));
      }
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Uri getAuthorizationUrl() {
    final url = kDebugMode ? localAuthorizationEndpoint : authorizationEndpoint;
    return url;
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      final credentials = await _credentialsStorage.read();
      final accessToken = credentials?.accessToken;

      try {
        await _dio.deleteUri<dynamic>(
          revocationEndpoint,
          options: Options(
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );
      } on DioError catch (e) {
        if (e.isNoConnectionError) {
          logger.e('No internet connect, did not revoke token');
        } else {
          logger.e(e.error);
          rethrow;
        }
      }
      await clearCredentialsStorage();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    } catch (e) {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> clearCredentialsStorage() async {
    try {
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  // Future<Either<AuthFailure, Credentials>> refresh(Credentials credentials) async {
  //   try {
  //     final refreshedCreds =
  //         await credentials.refresh(httpClient: client, identifier: clientId, secret: clientSecret);
  //     await _credentialsStorage.save(refreshedCreds);
  //     return right(refreshedCreds);
  //   } on FormatException {
  //     return left(const AuthFailure.server());
  //   } on AuthorizationException catch (e) {
  //     return left(AuthFailure.server('${e.error}: ${e.description}'));
  //   } on PlatformException {
  //     return left(const AuthFailure.storage());
  //   }
  // }
}
