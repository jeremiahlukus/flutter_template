// Package imports:
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'backend_headers.freezed.dart';
part 'backend_headers.g.dart';

@freezed
class BackendHeaders with _$BackendHeaders {
  const BackendHeaders._();
  const factory BackendHeaders({
    String? etag,
    PaginationLink? link,
  }) = _BackendHeaders;

  factory BackendHeaders.parse(Response response) {
    final link = response.headers.map['Link']?[0];

    return BackendHeaders(
      etag: response.headers.map['ETag']?[0],
      link: link == null
          ? null
          : PaginationLink.parse(
              link.split(','),
              requestUrl: response.requestOptions.uri.toString(),
            ),
    );
  }

  factory BackendHeaders.fromJson(Map<String, dynamic> json) => _$BackendHeadersFromJson(json);
}

@freezed
class PaginationLink with _$PaginationLink {
  const PaginationLink._();
  const factory PaginationLink({required int maxPage}) = _PaginationLink;
  factory PaginationLink.fromJson(Map<String, dynamic> json) => _$PaginationLinkFromJson(json);

  factory PaginationLink.parse(
    List<String> values, {
    required String requestUrl,
  }) {
    return PaginationLink(
      maxPage: _extractPageNumber(
        values.firstWhere(
          (e) => e.contains('rel="last"'),
          orElse: () => requestUrl,
        ),
      ),
    );
  }

  static int _extractPageNumber(String value) {
    final uriString = RegExp(
      r'[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)',
    ).stringMatch(value);
    return int.parse(Uri.parse(uriString!).queryParameters['page']!);
  }
}
