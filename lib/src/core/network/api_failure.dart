import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Why an API call failed, in terms the UI can act on.
///
/// Deliberately a small closed set rather than a passthrough of HTTP status
/// codes: a screen needs to know "retry", "sign in again", or "give up", and
/// nothing finer. `ApiFailure.statusCode` is kept for logs and for the rare
/// caller that genuinely needs it.
enum ApiFailureKind {
  /// No usable connection, or the request never got a response.
  network,

  /// The request took too long.
  timeout,

  /// 401/403 — the caller is not (or no longer) allowed.
  unauthorized,

  /// 404.
  notFound,

  /// 400/422 — the server rejected the payload.
  badRequest,

  /// 409 — the resource changed underneath us.
  conflict,

  /// 429 — slow down.
  rateLimited,

  /// 5xx.
  server,

  /// The call was cancelled by the caller.
  cancelled,

  /// Anything else, including a response body we could not parse.
  unknown;

  /// Whether retrying the identical request could plausibly succeed.
  ///
  /// Drives both the automatic retry interceptor and whether a screen offers a
  /// retry button, so the two can never disagree.
  bool get isRetryable => switch (this) {
    ApiFailureKind.network ||
    ApiFailureKind.timeout ||
    ApiFailureKind.rateLimited ||
    ApiFailureKind.server => true,
    _ => false,
  };

  /// Whether this means the session is gone and the user must sign in again.
  bool get requiresReauth => this == ApiFailureKind.unauthorized;
}

/// A failed API call.
///
/// Mirrors `AuthFailure` and `StorageFailure`: a machine-readable discriminator
/// plus an English fallback message, with the localised copy chosen by the UI.
@immutable
class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.method,
    this.path,
  });

  /// Classifies a [DioException]. The single conversion point.
  factory ApiFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;

    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => ApiFailureKind.timeout,
      DioExceptionType.cancel => ApiFailureKind.cancelled,
      DioExceptionType.connectionError => ApiFailureKind.network,
      DioExceptionType.badCertificate => ApiFailureKind.network,
      DioExceptionType.badResponse => _fromStatus(status),
      DioExceptionType.unknown => ApiFailureKind.network,
    };

    return ApiFailure(
      kind: kind,
      message: _describe(kind, status),
      statusCode: status,
      method: error.requestOptions.method,
      path: error.requestOptions.path,
    );
  }

  static ApiFailureKind _fromStatus(int? status) => switch (status) {
    401 || 403 => ApiFailureKind.unauthorized,
    404 => ApiFailureKind.notFound,
    409 => ApiFailureKind.conflict,
    429 => ApiFailureKind.rateLimited,
    400 || 422 => ApiFailureKind.badRequest,
    final int s when s >= 500 => ApiFailureKind.server,
    _ => ApiFailureKind.unknown,
  };

  static String _describe(ApiFailureKind kind, int? status) => switch (kind) {
    ApiFailureKind.network => 'Network unavailable. Check your connection.',
    ApiFailureKind.timeout => 'The request timed out.',
    ApiFailureKind.unauthorized => 'You are not allowed to do that.',
    ApiFailureKind.notFound => 'That was not found.',
    ApiFailureKind.badRequest => 'The request was rejected.',
    ApiFailureKind.conflict => 'Someone else changed this first.',
    ApiFailureKind.rateLimited => 'Too many requests. Try again shortly.',
    ApiFailureKind.server =>
      'The server had a problem${status == null ? '' : ' ($status)'}.',
    ApiFailureKind.cancelled => 'Request cancelled.',
    ApiFailureKind.unknown => 'Something went wrong.',
  };

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;
  final String? method;
  final String? path;

  bool get isRetryable => kind.isRetryable;

  bool get requiresReauth => kind.requiresReauth;

  @override
  String toString() =>
      'ApiFailure(${kind.name}${statusCode == null ? '' : ' $statusCode'}) '
      '${method ?? ''} ${path ?? ''}: $message';
}
