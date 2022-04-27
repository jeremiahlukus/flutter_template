// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';

class OAuth2Interceptor extends Interceptor {
  final WebAppAuthenticator _authenticator;
  final AuthNotifier _authNotifier;
  final Dio _dio;

  OAuth2Interceptor(this._authenticator, this._authNotifier, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final credentials = await _authenticator.getSignedInCredentials();
    final modifiedRequestOptions = options
      ..headers.addAll(
        credentials == null
            ? <String, String>{}
            : <String, String>{'Authorization': 'bearer ${credentials.accessToken}'},
      );
    handler.next(modifiedRequestOptions);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final errorResponse = err.response;
    if (errorResponse != null && errorResponse.statusCode == 401) {
      // final credentials = await _authenticator.getSignedInCredentials();

      // credentials != null && credentials.canRefresh
      //     ? await _authenticator.refresh(credentials)
      //     : await _authenticator.clearCredentialsStorage();
      await _authenticator.clearCredentialsStorage();
      await _authNotifier.checkAndUpdateAuthStatus();

      final refreshedCredentials = await _authenticator.getSignedInCredentials();
      if (refreshedCredentials != null) {
        handler.resolve(
          await _dio.fetch<Response<dynamic>>(
            errorResponse.requestOptions..headers['Authorization'] = 'bearer $refreshedCredentials',
          ),
        );
      }
    } else {
      handler.next(err);
    }
  }
}
