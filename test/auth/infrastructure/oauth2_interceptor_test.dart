// ignore_for_file: avoid_redundant_argument_values

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/auth/domain/auth_failure.dart';
import 'package:flutter_template/auth/infrastructure/oauth2_interceptor.dart';
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';

class MockWebAppAuthenticator extends Mock implements WebAppAuthenticator {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockDio extends Mock implements Dio {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}

class MockDioError extends Mock implements DioError {}

class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

class FakeResponse extends Fake implements Response<dynamic> {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeRequestOptions());
  });
  group('OAuth2Interceptor', () {
    const mockCredentialJson = '''
{
  "accessToken" : "d50d9fd00acf797ac409d5890fcc76669b727e63",
  "tokenType" : "Bearer",
  "expiresIn" : 1295998,
  "refreshToken" : "TZzj2yvtWlNP6BvG6UC5UKHXY2Ey6eEo80FSYax6Yv8",
  "scopes" :  ["admin"]
}''';
    group('.onRequest', () {
      test(
          "calls the handler's next method with an unmodified request options when WebAppAuthenticator returns null signed credentials ",
          () async {
        final WebAppAuthenticator mockWebAppAuthenticator = MockWebAppAuthenticator();
        final AuthNotifier mockAuthNotifier = MockAuthNotifier();
        final Dio mockDio = MockDio();
        when(mockWebAppAuthenticator.getSignedInCredentials).thenAnswer((invocation) => Future.value(null));

        final oAuth2Interceptor = OAuth2Interceptor(
          mockWebAppAuthenticator,
          mockAuthNotifier,
          mockDio,
        );

        final requestOptions = RequestOptions(path: '');
        final RequestInterceptorHandler mockRequestInterceptorHandler = MockRequestInterceptorHandler();

        await oAuth2Interceptor.onRequest(
          requestOptions,
          mockRequestInterceptorHandler,
        );

        verify<void>(() => mockRequestInterceptorHandler.next(requestOptions)).called(1);
      });

      test(
          "calls the handler's next method with a modified request options when WebAppAuthenticator returns null signed credentials ",
          () async {
        final WebAppAuthenticator mockWebAppAuthenticator = MockWebAppAuthenticator();
        final AuthNotifier mockAuthNotifier = MockAuthNotifier();
        final Dio mockDio = MockDio();

        final mockCredentials = Credentials.fromJson(mockCredentialJson);

        when(mockWebAppAuthenticator.getSignedInCredentials).thenAnswer((invocation) => Future.value(mockCredentials));

        final oAuth2Interceptor = OAuth2Interceptor(
          mockWebAppAuthenticator,
          mockAuthNotifier,
          mockDio,
        );

        final requestOptions = RequestOptions(path: '');
        final RequestInterceptorHandler mockRequestInterceptorHandler = MockRequestInterceptorHandler();

        await oAuth2Interceptor.onRequest(
          requestOptions,
          mockRequestInterceptorHandler,
        );

        final expectedRequestOptions = requestOptions
          ..headers.addAll(<String, String>{'Authorization': 'bearer ${mockCredentials.accessToken}'});

        verify<void>(
          () => mockRequestInterceptorHandler.next(expectedRequestOptions),
        ).called(1);
      });
    });

    group('.onError', () {
      test("calls the handler's next method with the passed DioError object if error response is null", () async {
        final WebAppAuthenticator mockWebAppAuthenticator = MockWebAppAuthenticator();
        final AuthNotifier mockAuthNotifier = MockAuthNotifier();
        final Dio mockDio = MockDio();

        final oAuth2Interceptor = OAuth2Interceptor(
          mockWebAppAuthenticator,
          mockAuthNotifier,
          mockDio,
        );

        final DioError mockDioError = MockDioError();
        final ErrorInterceptorHandler mockErrorInterceptorHandler = MockErrorInterceptorHandler();

        when(() => mockDioError.response).thenReturn(null);

        await oAuth2Interceptor.onError(
          mockDioError,
          mockErrorInterceptorHandler,
        );

        verify<void>(() => mockErrorInterceptorHandler.next(mockDioError)).called(1);
      });

      test(
          "calls the handler's next method with the passed DioError object if error response has a status code that is not 401 ",
          () async {
        final WebAppAuthenticator mockWebAppAuthenticator = MockWebAppAuthenticator();
        final AuthNotifier mockAuthNotifier = MockAuthNotifier();
        final Dio mockDio = MockDio();

        final oAuth2Interceptor = OAuth2Interceptor(
          mockWebAppAuthenticator,
          mockAuthNotifier,
          mockDio,
        );

        final DioError mockDioError = MockDioError();
        final ErrorInterceptorHandler mockErrorInterceptorHandler = MockErrorInterceptorHandler();
        final requestOptions = RequestOptions(path: '');

        final httpErrorCodesThatAreNot401 = <int>[
          HttpStatus.multipleChoices,
          HttpStatus.movedPermanently,
          HttpStatus.found,
          HttpStatus.movedTemporarily,
          HttpStatus.seeOther,
          HttpStatus.notModified,
          HttpStatus.useProxy,
          HttpStatus.temporaryRedirect,
          HttpStatus.permanentRedirect,
          HttpStatus.badRequest,
          HttpStatus.paymentRequired,
          HttpStatus.forbidden,
          HttpStatus.notFound,
          HttpStatus.methodNotAllowed,
          HttpStatus.notAcceptable,
          HttpStatus.proxyAuthenticationRequired,
          HttpStatus.requestTimeout,
          HttpStatus.conflict,
          HttpStatus.gone,
          HttpStatus.lengthRequired,
          HttpStatus.preconditionFailed,
          HttpStatus.requestEntityTooLarge,
          HttpStatus.requestUriTooLong,
          HttpStatus.unsupportedMediaType,
          HttpStatus.requestedRangeNotSatisfiable,
          HttpStatus.expectationFailed,
          HttpStatus.misdirectedRequest,
          HttpStatus.unprocessableEntity,
          HttpStatus.locked,
          HttpStatus.failedDependency,
          HttpStatus.upgradeRequired,
          HttpStatus.preconditionRequired,
          HttpStatus.tooManyRequests,
          HttpStatus.requestHeaderFieldsTooLarge,
          HttpStatus.connectionClosedWithoutResponse,
          HttpStatus.unavailableForLegalReasons,
          HttpStatus.clientClosedRequest,
          HttpStatus.internalServerError,
          HttpStatus.notImplemented,
          HttpStatus.badGateway,
          HttpStatus.serviceUnavailable,
          HttpStatus.gatewayTimeout,
          HttpStatus.httpVersionNotSupported,
          HttpStatus.variantAlsoNegotiates,
          HttpStatus.insufficientStorage,
          HttpStatus.loopDetected,
          HttpStatus.notExtended,
          HttpStatus.networkAuthenticationRequired,
          HttpStatus.networkConnectTimeoutError,
        ];

        for (final non401ErrorCode in httpErrorCodesThatAreNot401) {
          when(() => mockDioError.response).thenReturn(
            Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: non401ErrorCode,
            ),
          );

          await oAuth2Interceptor.onError(
            mockDioError,
            mockErrorInterceptorHandler,
          );

          verify<void>(() => mockErrorInterceptorHandler.next(mockDioError)).called(1);
        }
      });

      test(
          "calls the handler's resolve method with the result of Dio fetch DioError object if error response is not null with 401 status code",
          () async {
        final WebAppAuthenticator mockWebAppAuthenticator = MockWebAppAuthenticator();
        final AuthNotifier mockAuthNotifier = MockAuthNotifier();
        final Dio mockDio = MockDio();

        final mockCredentials = Credentials.fromJson(mockCredentialJson);

        final requestOptions = RequestOptions(path: '');

        when(mockWebAppAuthenticator.getSignedInCredentials).thenAnswer((invocation) => Future.value(mockCredentials));
        when(mockWebAppAuthenticator.clearCredentialsStorage).thenAnswer(
          (invocation) => Future.value(left(const AuthFailure.storage())),
        );
        when(mockAuthNotifier.checkAndUpdateAuthStatus).thenAnswer((invocation) => Future.value());
        when(() => mockDio.fetch<Response<dynamic>>(any())).thenAnswer(
          (_) => Future.value(
            Response(
              requestOptions: requestOptions,
              data: Response<dynamic>(
                requestOptions: requestOptions,
                statusCode: 401,
              ),
            ),
          ),
        );

        final oAuth2Interceptor = OAuth2Interceptor(
          mockWebAppAuthenticator,
          mockAuthNotifier,
          mockDio,
        );

        final DioError mockDioError = MockDioError();
        final ErrorInterceptorHandler mockErrorInterceptorHandler = MockErrorInterceptorHandler();

        when(() => mockDioError.response).thenReturn(
          Response<dynamic>(requestOptions: requestOptions, statusCode: 401),
        );

        await oAuth2Interceptor.onError(
          mockDioError,
          mockErrorInterceptorHandler,
        );

        verify<void>(() => mockErrorInterceptorHandler.resolve(any())).called(1);
      });
    });
  });
}
