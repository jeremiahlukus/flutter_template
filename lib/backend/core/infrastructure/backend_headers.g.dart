// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_headers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BackendHeaders _$$_BackendHeadersFromJson(Map<String, dynamic> json) => _$_BackendHeaders(
      etag: json['etag'] as String?,
      link: json['link'] == null ? null : PaginationLink.fromJson(json['link'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_BackendHeadersToJson(_$_BackendHeaders instance) => <String, dynamic>{
      'etag': instance.etag,
      'link': instance.link,
    };

_$_PaginationLink _$$_PaginationLinkFromJson(Map<String, dynamic> json) => _$_PaginationLink(
      maxPage: json['maxPage'] as int,
    );

Map<String, dynamic> _$$_PaginationLinkToJson(_$_PaginationLink instance) => <String, dynamic>{
      'maxPage': instance.maxPage,
    };
