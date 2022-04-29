import 'package:dio/dio.dart';
import 'package:flutter_template/backend/core/infrastructure/backend_headers.dart';
import 'package:test/test.dart';

void main() {
  group('BackendHeaders', () {
    group('.parse', () {
      test('returns a BackendHeaders object with null link if the response headers map contains no Link property', () {
        final response = Response<dynamic>(requestOptions: RequestOptions(path: ''), headers: Headers.fromMap({}));
        final backendHeaders = BackendHeaders.parse(response);
        final actualData = backendHeaders.link;
        // ignore: prefer_void_to_null
        const Null expectedData = null;

        expect(actualData, expectedData);
      });

      test('returns a BackendHeaders object with a non-null link if the response headers map contains a Link property',
          () {
        final response = Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            headers: Headers.fromMap({
              'link': ['https://www.example.com?page=10&rel="last"']
            }));
        final backendHeaders = BackendHeaders.parse(response);
        final actualData = backendHeaders.link;
        // ignore: prefer_void_to_null
        const expectedData = isNotNull;

        expect(actualData, expectedData);
      });
    });
  });

  group('PaginationLink', () {
    test('', () {});
  });
}
