import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:flutter/services.dart';
import 'package:flutter_template/auth/domain/auth_failure.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:flutter_template/core/infrastructure/dio_extensions.dart';
import 'package:oauth2/oauth2.dart';
import 'package:http/http.dart' as http;

class WebAppAuthenticator {
  WebAppAuthenticator(this._credentialsStorage, this._dio);

  final CredentialsStorage _credentialsStorage;
  final Dio _dio;
  static final authorizationEndpoint = Uri.parse('http://127.0.0.1:3000/users/sign_in');
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
    return authorizationEndpoint;
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      final accessToken = await _credentialsStorage.read().then((credentials) => credentials?.accessToken);

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
          //print('token not revoked');
        } else {
          print(e.error);
          rethrow;
        }
      }
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}

//   Future<Either<AuthFailure, Credentials>> refresh(Credentials credentials) async {
//     try {
//       final refreshedCreds =
//           await credentials.refresh(httpClient: client, identifier: clientId, secret: clientSecret);
//       await _credentialsStorage.save(refreshedCreds);
//       return right(refreshedCreds);
//     } on FormatException {
//       return left(const AuthFailure.server());
//     } on AuthorizationException catch (e) {
//       return left(AuthFailure.server('${e.error}: ${e.description}'));
//     } on PlatformException {
//       return left(const AuthFailure.storage());
//     }
//   }
// }