// Package imports:
import 'package:dio/dio.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/backend/core/infrastructure/backend_headers.dart';

void main() {
  group('BackendHeaders', () {
    group('.parse', () {
      test(
          'returns a BackendHeaders object with null link if the response headers map contains no Link property and response request options contain no url',
          () {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          headers: Headers.fromMap({}),
        );
        final backendHeaders = BackendHeaders.parse(response);
        final actualData = backendHeaders.link;
        // ignore: prefer_void_to_null
        const Null expectedData = null;

        expect(actualData, expectedData);
      });

      test(
          'returns a BackendHeaders object with a non-null link if the response headers map contains a Link property that contains rel="last"',
          () {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          headers: Headers.fromMap({
            'link': ['https://www.example.com?page=10&rel="last"']
          }),
        );
        final backendHeaders = BackendHeaders.parse(response);
        final actualData = backendHeaders.link;
        // ignore: prefer_void_to_null
        const expectedData = isNotNull;

        expect(actualData, expectedData);
      });

      test(
          'returns a BackendHeaders object with a non-null link if the response headers map contains a Link property that does not contains rel="last"  and response request options contain a url',
          () {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(
            path: '?page=10&rel="last',
            baseUrl: 'https://www.example.com',
          ),
          headers: Headers.fromMap({
            'link': ['https://www.example.com']
          }),
        );
        final backendHeaders = BackendHeaders.parse(response);
        final actualData = backendHeaders.link;
        // ignore: prefer_void_to_null
        const expectedData = isNotNull;

        expect(actualData, expectedData);
      });
    });

    group('PaginationLink', () {
      test('.fromJson returns a PaginationLink object with the correct maxPage', () {
        final paginationJson = {'maxPage': 2};
        final paginationLink = PaginationLink.fromJson(paginationJson);

        final actualData = paginationLink.maxPage;
        const expectedData = 2;

        expect(actualData, expectedData);
      });
    });
  });
}
