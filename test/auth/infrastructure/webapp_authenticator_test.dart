import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/auth/domain/auth_failure.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:test/test.dart';

class MockCredentialStorage extends Mock implements CredentialsStorage {}

class MockDio extends Mock implements Dio {}

class MockWebAppAuthenticator extends Mock implements WebAppAuthenticator {}

class MockResponse extends Mock implements Response<dynamic> {}

class FakeCredentials extends Fake implements Credentials {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCredentials());
  });

  group('WebAppAuthenticator', () {
    const mockCredentialJson = '''
{
  "accessToken" : "d50d9fd00acf797ac409d5890fcc76669b727e63",
  "tokenType" : "Bearer",
  "expiresIn" : 1295998,
  "refreshToken" : "TZzj2yvtWlNP6BvG6UC5UKHXY2Ey6eEo80FSYax6Yv8",
  "scopes" :  ["admin"]
}''';

    final queryParams = <String, String>{
      'state': jsonEncode(['', ''])
    };
    group('.getSignedInCredentials', () {
      test('returns the exact Credentials returned by CredentialStorage.read()',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        final credential = Credentials.fromJson(mockCredentialJson);

        when(mockCredentialsStorage.read)
            .thenAnswer((_) => Future.value(credential));

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignedCredentials =
            await webAppAuthenticator.getSignedInCredentials();
        final expectedSignedCredentials = credential;

        expect(actualSignedCredentials, expectedSignedCredentials);
      });

      test('retuns null on PlatformException', () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(mockCredentialsStorage.read)
            .thenThrow(PlatformException(code: ''));

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignedCredentials =
            await webAppAuthenticator.getSignedInCredentials();
        const Credentials? expectedSignedCredentials = null;

        expect(actualSignedCredentials, expectedSignedCredentials);
      });
    });

    group('.handleAuthorizationResponse', () {
      test('returns Right<AuthFailure, Unit> when it runs without Exceptions',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(() => mockCredentialsStorage.save(any()))
            .thenAnswer((invocation) => Future.value());

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualResult =
            await webAppAuthenticator.handleAuthorizationResponse(queryParams);
        final expectedResult = isA<Right<AuthFailure, Unit>>();

        expect(actualResult, expectedResult);
      });

      test('returns Left<AuthFailure, Unit> on AuthorizationException',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(
          () => mockCredentialsStorage.save(any()),
        ).thenThrow(AuthorizationException('', '', Uri()));

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualResult =
            await webAppAuthenticator.handleAuthorizationResponse(queryParams);
        final expectedResult = isA<Left<AuthFailure, Unit>>();

        expect(actualResult, expectedResult);
      });

      test('returns Left<AuthFailure, Unit> on FormatException', () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(
          () => mockCredentialsStorage.save(any()),
        ).thenThrow(const FormatException());

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualResult =
            await webAppAuthenticator.handleAuthorizationResponse(queryParams);
        final expectedResult = isA<Left<AuthFailure, Unit>>();

        expect(actualResult, expectedResult);
      });
      test('returns Left<AuthFailure, Unit> on PlatformException', () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(
          () => mockCredentialsStorage.save(any()),
        ).thenThrow(PlatformException(code: ''));

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualResult =
            await webAppAuthenticator.handleAuthorizationResponse(queryParams);
        final expectedResult = isA<Left<AuthFailure, Unit>>();

        expect(actualResult, expectedResult);
      });
    });

    group('.getAuthorizationUrl', () {
      test('returns the value of WebAppAuthenticator.authorizationEndpoint',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualAuthorizationUrl =
            webAppAuthenticator.getAuthorizationUrl();
        final expectedAuthorizationUrl =
            WebAppAuthenticator.authorizationEndpoint;

        expect(actualAuthorizationUrl, expectedAuthorizationUrl);
      });
    });

    group('.signOut', () {
      test('returns Right<AuthFailure, Unit> if there are no Exceptions',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();
        final credential = Credentials.fromJson(mockCredentialJson);
        final Response<dynamic> mockResponse = MockResponse();

        when(mockCredentialsStorage.read)
            .thenAnswer((_) => Future.value(credential));

        when(mockCredentialsStorage.clear).thenAnswer((_) => Future.value());

        when(
          () => mockDio.deleteUri<dynamic>(
            WebAppAuthenticator.revocationEndpoint,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => Future.value(mockResponse));

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignOutReturnValue = await webAppAuthenticator.signOut();
        final expectedSignOutReturnValue = isA<Right<AuthFailure, Unit>>();

        expect(actualSignOutReturnValue, expectedSignOutReturnValue);
      });

      test(
          'returns Right<AuthFailure, Unit> on DioError that is NoConnectionError',
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();
        final credential = Credentials.fromJson(mockCredentialJson);

        when(mockCredentialsStorage.read)
            .thenAnswer((_) => Future.value(credential));

        when(mockCredentialsStorage.clear).thenAnswer((_) => Future.value());

        when(
          () => mockDio.deleteUri<dynamic>(
            WebAppAuthenticator.revocationEndpoint,
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioError(
            error: const SocketException(''),
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignOutReturnValue = await webAppAuthenticator.signOut();
        final expectedSignOutReturnValue = isA<Right<AuthFailure, Unit>>();

        expect(actualSignOutReturnValue, expectedSignOutReturnValue);
      });

      test('returns Left<AuthFailure, Unit> on PlatformException', () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();

        when(mockCredentialsStorage.read)
            .thenThrow(PlatformException(code: ''));

        when(mockCredentialsStorage.clear).thenAnswer((_) => Future.value());

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignOutReturnValue = await webAppAuthenticator.signOut();
        final expectedSignOutReturnValue = isA<Left<AuthFailure, Unit>>();

        expect(actualSignOutReturnValue, expectedSignOutReturnValue);
      });

      test(
          "returns Left<AuthFailure, Unit> on DioError that isn't NoConnectionError ",
          () async {
        final CredentialsStorage mockCredentialsStorage =
            MockCredentialStorage();
        final Dio mockDio = MockDio();
        final credential = Credentials.fromJson(mockCredentialJson);

        when(
          () => mockDio.deleteUri<dynamic>(
            WebAppAuthenticator.revocationEndpoint,
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioError(
            type: DioErrorType.connectTimeout,
            error: const SocketException(''),
            requestOptions: RequestOptions(path: ''),
          ),
        );

        when(mockCredentialsStorage.read)
            .thenAnswer((_) => Future.value(credential));

        when(mockCredentialsStorage.clear).thenAnswer((_) => Future.value());

        final webAppAuthenticator =
            WebAppAuthenticator(mockCredentialsStorage, mockDio);

        final actualSignOutReturnValue = await webAppAuthenticator.signOut();
        final expectedSignOutReturnValue = isA<Left<AuthFailure, Unit>>();

        expect(actualSignOutReturnValue, expectedSignOutReturnValue);
      });
    });
  });
}
