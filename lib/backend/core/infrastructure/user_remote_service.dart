// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:flutter_template/backend/core/infrastructure/backend_base_url.dart';
import 'package:flutter_template/backend/core/infrastructure/backend_headers.dart';
import 'package:flutter_template/backend/core/infrastructure/backend_headers_cache.dart';
import 'package:flutter_template/backend/core/infrastructure/user_dto.dart';
import 'package:flutter_template/core/infrastructure/dio_extensions.dart';
import 'package:flutter_template/core/infrastructure/network_exceptions.dart';
import 'package:flutter_template/core/infrastructure/remote_response.dart';

class UserRemoteService {
  UserRemoteService(this._dio, this._backendHeadersCache);
  final Dio _dio;
  final BackendHeadersCache _backendHeadersCache;

  Future<RemoteResponse<UserDTO>> getUserDetails() async {
    final requestUri = Uri.http(
      BackendConstants().backendBaseUrl(),
      'api/v1/me',
    );

    final previousHeaders = await _backendHeadersCache.getHeaders(requestUri);
    try {
      final response = await _dio.getUri<dynamic>(
        requestUri,
        options: Options(
          headers: <String, String>{
            'If-None-Match': previousHeaders?.etag ?? '',
          },
        ),
      );
      if (response.statusCode == 304) {
        return const RemoteResponse.notModified();
      } else if (response.statusCode == 200) {
        final headers = BackendHeaders.parse(response);
        await _backendHeadersCache.saveHeaders(requestUri, headers);

        final convertedData = UserDTO.fromJson(response.data as Map<String, dynamic>);
        return RemoteResponse.withNewData(convertedData);
      } else {
        throw RestApiException(response.statusCode);
      }
    } on DioError catch (e) {
      if (e.isNoConnectionError) {
        return const RemoteResponse.noConnection();
      } else if (e.response != null) {
        throw RestApiException(e.response?.statusCode);
      } else {
        rethrow;
      }
    }
  }
}
