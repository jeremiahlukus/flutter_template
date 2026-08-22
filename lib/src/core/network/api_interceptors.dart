import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/network/api_failure.dart';

/// Attaches the signed-in user's Firebase ID token to every request.
///
/// Reads the token per-request rather than caching it: Firebase rotates ID
/// tokens hourly, and a cached one produces 401s that look like a backend bug.
/// `getIdToken()` returns the cached token until it is close to expiry, so this
/// is cheap.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Opt out per-request for endpoints that must stay anonymous.
    if (options.extra['anonymous'] == true) return handler.next(options);

    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (error) {
      // A token failure is not fatal here: let the request go out unsigned and
      // let the server return 401, which the app already handles.
      AppLogger.instance.w('Could not attach an ID token: $error');
    }
    return handler.next(options);
  }
}

/// Retries a failed request a bounded number of times, with backoff.
///
/// Only retries what [ApiFailureKind.isRetryable] says is worth retrying, and
/// only idempotent methods — replaying a POST could double-charge a card or
/// create two records.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    Future<void> Function(Duration)? sleep,
  }) : _dio = dio,
       _sleep = sleep ?? Future<void>.delayed;

  final Dio _dio;
  final int maxAttempts;
  final Duration baseDelay;
  final Future<void> Function(Duration) _sleep;

  /// Methods safe to replay. Deliberately excludes POST and PATCH.
  static const idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retryAttempt'] as int? ?? 0) + 1;
    final failure = ApiFailure.fromDio(err);

    final shouldRetry =
        failure.isRetryable &&
        idempotentMethods.contains(options.method.toUpperCase()) &&
        attempt < maxAttempts;

    if (!shouldRetry) return handler.next(err);

    // Exponential backoff: 300ms, 600ms, 1200ms…
    await _sleep(baseDelay * (1 << (attempt - 1)));
    AppLogger.instance.i(
      'Retrying ${options.method} ${options.path} '
      '(attempt ${attempt + 1}/$maxAttempts)',
    );

    try {
      final response = await _dio.fetch<dynamic>(
        options..extra['retryAttempt'] = attempt,
      );
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}

/// Logs requests and failures. Verbose only where the environment says so.
class ApiLogInterceptor extends Interceptor {
  const ApiLogInterceptor({required this.verbose});

  final bool verbose;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (verbose) {
      AppLogger.instance.d('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (verbose) {
      AppLogger.instance.d(
        '← ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Failures are always logged, verbose or not — a silent 500 in production is
    // exactly what you need the log for.
    AppLogger.instance.w('✗ ${ApiFailure.fromDio(err)}');
    handler.next(err);
  }
}
