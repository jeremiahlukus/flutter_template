import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/network/api_client.dart';
import 'package:flutter_template/src/core/network/api_interceptors.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';

/// Timeouts, chosen to fail faster than a user's patience.
///
/// A request that has not connected in 10s is not going to; hanging until the
/// OS gives up (often 60s+) just leaves a spinner on screen.
abstract final class ApiTimeouts {
  static const connect = Duration(seconds: 10);
  static const send = Duration(seconds: 20);
  static const receive = Duration(seconds: 20);
}

/// The configured Dio instance.
///
/// Interceptor order matters: auth first so the token is attached before
/// anything logs the request, logging next so it sees the final headers, retry
/// last so it wraps the whole chain.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: ApiTimeouts.connect,
      sendTimeout: ApiTimeouts.send,
      receiveTimeout: ApiTimeouts.receive,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      // Never throw on a status code; `ApiFailure` classifies them instead.
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.addAll([
    AuthTokenInterceptor(ref.watch(firebaseAuthProvider)),
    ApiLogInterceptor(verbose: config.verboseLogging),
    RetryInterceptor(dio: dio),
  ]);

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
