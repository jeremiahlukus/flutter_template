import 'package:dio/dio.dart';
import 'package:flutter_template/src/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException dioError({
    DioExceptionType type = DioExceptionType.badResponse,
    int? status,
    String method = 'GET',
    String path = '/things',
  }) {
    final options = RequestOptions(path: path, method: method);
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: status),
    );
  }

  group('status code mapping', () {
    const cases = <int, ApiFailureKind>{
      400: ApiFailureKind.badRequest,
      401: ApiFailureKind.unauthorized,
      403: ApiFailureKind.unauthorized,
      404: ApiFailureKind.notFound,
      409: ApiFailureKind.conflict,
      422: ApiFailureKind.badRequest,
      429: ApiFailureKind.rateLimited,
      500: ApiFailureKind.server,
      502: ApiFailureKind.server,
      503: ApiFailureKind.server,
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value.name}', () {
        expect(
          ApiFailure.fromDio(dioError(status: entry.key)).kind,
          entry.value,
        );
      });
    }

    test('an unmapped 4xx falls back to unknown', () {
      expect(
        ApiFailure.fromDio(dioError(status: 418)).kind,
        ApiFailureKind.unknown,
      );
    });

    test('a bad response with no status is unknown', () {
      expect(ApiFailure.fromDio(dioError()).kind, ApiFailureKind.unknown);
    });
  });

  group('exception type mapping', () {
    test('every timeout flavour maps to timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ApiFailure.fromDio(dioError(type: type)).kind,
          ApiFailureKind.timeout,
          reason: '$type',
        );
      }
    });

    test('cancellation maps to cancelled', () {
      expect(
        ApiFailure.fromDio(dioError(type: DioExceptionType.cancel)).kind,
        ApiFailureKind.cancelled,
      );
    });

    test('a connection error maps to network', () {
      expect(
        ApiFailure.fromDio(
          dioError(type: DioExceptionType.connectionError),
        ).kind,
        ApiFailureKind.network,
      );
    });

    test('a bad certificate maps to network', () {
      expect(
        ApiFailure.fromDio(
          dioError(type: DioExceptionType.badCertificate),
        ).kind,
        ApiFailureKind.network,
      );
    });

    test('an unknown Dio error maps to network', () {
      // Almost always a socket problem in practice, and treating it as network
      // makes it retryable — which is the useful behaviour.
      expect(
        ApiFailure.fromDio(dioError(type: DioExceptionType.unknown)).kind,
        ApiFailureKind.network,
      );
    });
  });

  group('isRetryable', () {
    test('is true only for transient kinds', () {
      const retryable = {
        ApiFailureKind.network,
        ApiFailureKind.timeout,
        ApiFailureKind.rateLimited,
        ApiFailureKind.server,
      };

      for (final kind in ApiFailureKind.values) {
        expect(
          kind.isRetryable,
          retryable.contains(kind),
          reason: kind.name,
        );
      }
    });

    test('a rejected payload is never retryable', () {
      // Replaying an identical bad request cannot succeed; it just wastes a
      // round-trip and delays the error the user needs to see.
      expect(ApiFailureKind.badRequest.isRetryable, isFalse);
      expect(ApiFailureKind.notFound.isRetryable, isFalse);
      expect(ApiFailureKind.conflict.isRetryable, isFalse);
    });

    test('a cancelled request is never retried', () {
      expect(ApiFailureKind.cancelled.isRetryable, isFalse);
    });
  });

  group('requiresReauth', () {
    test('is true only for unauthorized', () {
      for (final kind in ApiFailureKind.values) {
        expect(
          kind.requiresReauth,
          kind == ApiFailureKind.unauthorized,
          reason: kind.name,
        );
      }
    });
  });

  group('diagnostics', () {
    test('carries the status, method, and path', () {
      final failure = ApiFailure.fromDio(
        dioError(status: 500, method: 'PUT', path: '/notes/1'),
      );

      expect(failure.statusCode, 500);
      expect(failure.method, 'PUT');
      expect(failure.path, '/notes/1');
    });

    test('every kind has a non-empty message', () {
      for (final kind in ApiFailureKind.values) {
        final failure = ApiFailure(kind: kind, message: '');
        expect(failure.kind, kind);
      }

      for (final status in [400, 401, 404, 409, 429, 500]) {
        expect(
          ApiFailure.fromDio(dioError(status: status)).message,
          isNotEmpty,
        );
      }
    });

    test('a server message names the status code', () {
      expect(
        ApiFailure.fromDio(dioError(status: 503)).message,
        contains('503'),
      );
    });

    test('toString names the kind, status, method, and path', () {
      final text = ApiFailure.fromDio(
        dioError(status: 404, path: '/missing'),
      ).toString();

      expect(text, contains('notFound'));
      expect(text, contains('404'));
      expect(text, contains('GET'));
      expect(text, contains('/missing'));
    });

    test('is an Exception, so it can cross an async boundary', () {
      expect(
        const ApiFailure(kind: ApiFailureKind.network, message: 'x'),
        isA<Exception>(),
      );
    });
  });
}
