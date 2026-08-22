import 'package:dio/dio.dart';
import 'package:flutter_template/src/core/network/api_failure.dart';

/// Thin, typed wrapper over Dio.
///
/// Exists so feature code never sees a `DioException`: every failure arrives as
/// an [ApiFailure], matching how `AuthRepository` and `StorageRepository` treat
/// their SDKs. That is what keeps error handling uniform across the app — and
/// what makes a repository testable against `DioAdapter`-style fakes.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  /// The underlying Dio, for the rare caller that needs something bespoke
  /// (multipart progress, a raw stream). Prefer the typed methods.
  Dio get raw => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? data)? decode,
    bool anonymous = false,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<dynamic>(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
      options: _options(anonymous),
    ),
    decode,
  );

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? data)? decode,
    bool anonymous = false,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: query,
      cancelToken: cancelToken,
      options: _options(anonymous),
    ),
    decode,
  );

  Future<T> put<T>(
    String path, {
    Object? body,
    T Function(Object? data)? decode,
    bool anonymous = false,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.put<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
      options: _options(anonymous),
    ),
    decode,
  );

  Future<T> delete<T>(
    String path, {
    Object? body,
    T Function(Object? data)? decode,
    bool anonymous = false,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.delete<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
      options: _options(anonymous),
    ),
    decode,
  );

  Options _options(bool anonymous) =>
      Options(extra: anonymous ? {'anonymous': true} : null);

  /// Runs [request] and normalises every throw into an [ApiFailure].
  ///
  /// [decode] converts the response body. Without it, `T` must be `void` or
  /// match the raw body type — a decode failure is reported as
  /// [ApiFailureKind.unknown] rather than escaping as a `TypeError`, because a
  /// backend contract change should not look like a crash.
  Future<T> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Object? data)? decode,
  ) async {
    try {
      final response = await request();
      if (decode != null) return decode(response.data);
      if (T == Never || null is T) return null as T;
      return response.data as T;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      throw ApiFailure(
        kind: ApiFailureKind.unknown,
        message: 'Could not read the response: $error',
      );
    }
  }
}
