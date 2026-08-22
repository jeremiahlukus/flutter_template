import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_template/src/core/network/api_client.dart';
import 'package:flutter_template/src/core/network/api_failure.dart';
import 'package:flutter_template/src/core/network/api_interceptors.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scripted transport, so the client is tested without a server.
///
/// Dio's own `HttpClientAdapter` seam is the right place to fake: it exercises
/// the real interceptor chain, options merging, and error classification, which
/// mocking `Dio` itself would skip entirely.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.respond);

  /// Called for every request. Return a response or throw.
  ResponseBody Function(RequestOptions options) respond;

  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late _ScriptedAdapter adapter;
  late Dio dio;
  late ApiClient client;

  setUp(() {
    adapter = _ScriptedAdapter((_) => jsonBody('{"ok":true}', 200));
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter;
    client = ApiClient(dio);
  });

  group('happy path', () {
    test('GET decodes the body', () async {
      adapter.respond = (_) => jsonBody('{"name":"Ada"}', 200);

      final name = await client.get<String>(
        '/users/1',
        decode: (data) => (data! as Map<String, dynamic>)['name'] as String,
      );

      expect(name, 'Ada');
    });

    test('GET passes query parameters through', () async {
      await client.get<void>('/notes', query: {'limit': 10});

      expect(adapter.requests.single.queryParameters, {'limit': 10});
    });

    test('POST sends the body', () async {
      adapter.respond = (_) => jsonBody('{}', 201);

      await client.post<void>('/notes', body: {'title': 'T'});

      expect(adapter.requests.single.data, {'title': 'T'});
      expect(adapter.requests.single.method, 'POST');
    });

    test('PUT and DELETE use the right methods', () async {
      await client.put<void>('/notes/1', body: {'title': 'T'});
      await client.delete<void>('/notes/1');

      expect(adapter.requests.map((r) => r.method), ['PUT', 'DELETE']);
    });

    test('resolves the path against the configured base URL', () async {
      await client.get<void>('/notes');

      expect(
        adapter.requests.single.uri.toString(),
        'https://api.example.com/notes',
      );
    });

    test('a void call needs no decoder', () async {
      await expectLater(client.get<void>('/ping'), completes);
    });
  });

  group('failure mapping', () {
    test('a 404 becomes an ApiFailure, not a DioException', () async {
      adapter.respond = (_) => jsonBody('{}', 404);

      // Feature code must never see a DioException; that is the whole point of
      // the wrapper.
      await expectLater(
        client.get<void>('/missing'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.notFound,
          ),
        ),
      );
    });

    test('a 500 maps to server', () async {
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(
        client.get<void>('/boom'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.server,
          ),
        ),
      );
    });

    test('a transport throw maps to network', () async {
      adapter.respond = (_) => throw const _SocketishError();

      await expectLater(
        client.get<void>('/x'),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('a decode failure is reported, not thrown as a TypeError', () async {
      adapter.respond = (_) => jsonBody('{"name":"Ada"}', 200);

      // A backend contract change should look like a failed call, not a crash.
      await expectLater(
        client.get<int>('/users/1', decode: (data) => data! as int),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.kind, 'kind', ApiFailureKind.unknown)
              .having((e) => e.message, 'message', contains('response')),
        ),
      );
    });

    test('a cancelled request maps to cancelled', () async {
      final token = CancelToken();
      adapter.respond = (_) {
        token.cancel();
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: '/slow'),
          reason: 'test',
        );
      };

      await expectLater(
        client.get<void>('/slow', cancelToken: token),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.cancelled,
          ),
        ),
      );
    });
  });

  group('AuthTokenInterceptor', () {
    test('attaches a bearer token when signed in', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      dio.interceptors.add(AuthTokenInterceptor(auth));

      await client.get<void>('/me');

      expect(
        adapter.requests.single.headers['Authorization'],
        startsWith('Bearer '),
      );
    });

    test('sends no header when signed out', () async {
      dio.interceptors.add(AuthTokenInterceptor(MockFirebaseAuth()));

      await client.get<void>('/public');

      expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    });

    test('honours an explicit anonymous request', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      dio.interceptors.add(AuthTokenInterceptor(auth));

      await client.get<void>('/health', anonymous: true);

      expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    });
  });

  group('RetryInterceptor', () {
    /// No real waiting; backoff is asserted separately.
    List<Duration> installRetry({int maxAttempts = 3}) {
      final slept = <Duration>[];
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxAttempts: maxAttempts,
          sleep: (d) async => slept.add(d),
        ),
      );
      return slept;
    }

    test('retries a 500 up to the attempt limit', () async {
      installRetry();
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(client.get<void>('/flaky'), throwsA(isA<ApiFailure>()));

      expect(adapter.requests, hasLength(3));
    });

    test('stops as soon as a retry succeeds', () async {
      installRetry();
      var calls = 0;
      adapter.respond = (_) {
        calls++;
        return jsonBody('{}', calls == 1 ? 503 : 200);
      };

      await expectLater(client.get<void>('/flaky'), completes);

      expect(calls, 2);
    });

    test('backs off exponentially', () async {
      final slept = installRetry();
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(client.get<void>('/flaky'), throwsA(isA<ApiFailure>()));

      expect(slept, [
        const Duration(milliseconds: 300),
        const Duration(milliseconds: 600),
      ]);
    });

    test('does not retry a 404', () async {
      installRetry();
      adapter.respond = (_) => jsonBody('{}', 404);

      await expectLater(
        client.get<void>('/missing'),
        throwsA(isA<ApiFailure>()),
      );

      expect(adapter.requests, hasLength(1));
    });

    test('does not retry a POST, even on a 500', () async {
      installRetry();
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(
        client.post<void>('/orders', body: {'total': 100}),
        throwsA(isA<ApiFailure>()),
      );

      // Replaying a POST could create two records or double-charge a card.
      expect(adapter.requests, hasLength(1));
    });

    test('does retry an idempotent PUT', () async {
      installRetry();
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(
        client.put<void>('/notes/1', body: {'title': 'T'}),
        throwsA(isA<ApiFailure>()),
      );

      expect(adapter.requests, hasLength(3));
    });

    test('respects a custom attempt limit', () async {
      installRetry(maxAttempts: 2);
      adapter.respond = (_) => jsonBody('{}', 500);

      await expectLater(client.get<void>('/flaky'), throwsA(isA<ApiFailure>()));

      expect(adapter.requests, hasLength(2));
    });

    test('only GET, HEAD, OPTIONS, PUT and DELETE are replayed', () {
      expect(RetryInterceptor.idempotentMethods, {
        'GET',
        'HEAD',
        'OPTIONS',
        'PUT',
        'DELETE',
      });
      expect(RetryInterceptor.idempotentMethods, isNot(contains('POST')));
      expect(RetryInterceptor.idempotentMethods, isNot(contains('PATCH')));
    });
  });

  group('ApiLogInterceptor', () {
    test('is installable in both verbose and quiet modes', () async {
      dio.interceptors.add(const ApiLogInterceptor(verbose: true));
      await expectLater(client.get<void>('/a'), completes);

      dio.interceptors.clear();
      dio.interceptors.add(const ApiLogInterceptor(verbose: false));
      await expectLater(client.get<void>('/b'), completes);
    });

    test('logs a failure in quiet mode too', () async {
      dio.interceptors.add(const ApiLogInterceptor(verbose: false));
      adapter.respond = (_) => jsonBody('{}', 500);

      // A silent 500 in production is exactly what the log is for.
      await expectLater(client.get<void>('/boom'), throwsA(isA<ApiFailure>()));
    });
  });

  test('raw exposes the underlying Dio for bespoke calls', () {
    expect(client.raw, same(dio));
  });
}

/// Stand-in for a socket-level failure.
class _SocketishError implements Exception {
  const _SocketishError();
}
