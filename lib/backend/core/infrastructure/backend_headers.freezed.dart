// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'backend_headers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

BackendHeaders _$BackendHeadersFromJson(Map<String, dynamic> json) {
  return _BackendHeaders.fromJson(json);
}

/// @nodoc
class _$BackendHeadersTearOff {
  const _$BackendHeadersTearOff();

  _BackendHeaders call({String? etag, PaginationLink? link}) {
    return _BackendHeaders(
      etag: etag,
      link: link,
    );
  }

  BackendHeaders fromJson(Map<String, Object?> json) {
    return BackendHeaders.fromJson(json);
  }
}

/// @nodoc
const $BackendHeaders = _$BackendHeadersTearOff();

/// @nodoc
mixin _$BackendHeaders {
  String? get etag => throw _privateConstructorUsedError;
  PaginationLink? get link => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BackendHeadersCopyWith<BackendHeaders> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackendHeadersCopyWith<$Res> {
  factory $BackendHeadersCopyWith(BackendHeaders value, $Res Function(BackendHeaders) then) =
      _$BackendHeadersCopyWithImpl<$Res>;
  $Res call({String? etag, PaginationLink? link});

  $PaginationLinkCopyWith<$Res>? get link;
}

/// @nodoc
class _$BackendHeadersCopyWithImpl<$Res> implements $BackendHeadersCopyWith<$Res> {
  _$BackendHeadersCopyWithImpl(this._value, this._then);

  final BackendHeaders _value;
  // ignore: unused_field
  final $Res Function(BackendHeaders) _then;

  @override
  $Res call({
    Object? etag = freezed,
    Object? link = freezed,
  }) {
    return _then(_value.copyWith(
      etag: etag == freezed
          ? _value.etag
          : etag // ignore: cast_nullable_to_non_nullable
              as String?,
      link: link == freezed
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as PaginationLink?,
    ));
  }

  @override
  $PaginationLinkCopyWith<$Res>? get link {
    if (_value.link == null) {
      return null;
    }

    return $PaginationLinkCopyWith<$Res>(_value.link!, (value) {
      return _then(_value.copyWith(link: value));
    });
  }
}

/// @nodoc
abstract class _$BackendHeadersCopyWith<$Res> implements $BackendHeadersCopyWith<$Res> {
  factory _$BackendHeadersCopyWith(_BackendHeaders value, $Res Function(_BackendHeaders) then) =
      __$BackendHeadersCopyWithImpl<$Res>;
  @override
  $Res call({String? etag, PaginationLink? link});

  @override
  $PaginationLinkCopyWith<$Res>? get link;
}

/// @nodoc
class __$BackendHeadersCopyWithImpl<$Res> extends _$BackendHeadersCopyWithImpl<$Res>
    implements _$BackendHeadersCopyWith<$Res> {
  __$BackendHeadersCopyWithImpl(_BackendHeaders _value, $Res Function(_BackendHeaders) _then)
      : super(_value, (v) => _then(v as _BackendHeaders));

  @override
  _BackendHeaders get _value => super._value as _BackendHeaders;

  @override
  $Res call({
    Object? etag = freezed,
    Object? link = freezed,
  }) {
    return _then(_BackendHeaders(
      etag: etag == freezed
          ? _value.etag
          : etag // ignore: cast_nullable_to_non_nullable
              as String?,
      link: link == freezed
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as PaginationLink?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BackendHeaders extends _BackendHeaders {
  const _$_BackendHeaders({this.etag, this.link}) : super._();

  factory _$_BackendHeaders.fromJson(Map<String, dynamic> json) => _$$_BackendHeadersFromJson(json);

  @override
  final String? etag;
  @override
  final PaginationLink? link;

  @override
  String toString() {
    return 'BackendHeaders(etag: $etag, link: $link)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackendHeaders &&
            const DeepCollectionEquality().equals(other.etag, etag) &&
            const DeepCollectionEquality().equals(other.link, link));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(etag), const DeepCollectionEquality().hash(link));

  @JsonKey(ignore: true)
  @override
  _$BackendHeadersCopyWith<_BackendHeaders> get copyWith =>
      __$BackendHeadersCopyWithImpl<_BackendHeaders>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BackendHeadersToJson(this);
  }
}

abstract class _BackendHeaders extends BackendHeaders {
  const factory _BackendHeaders({String? etag, PaginationLink? link}) = _$_BackendHeaders;
  const _BackendHeaders._() : super._();

  factory _BackendHeaders.fromJson(Map<String, dynamic> json) = _$_BackendHeaders.fromJson;

  @override
  String? get etag;
  @override
  PaginationLink? get link;
  @override
  @JsonKey(ignore: true)
  _$BackendHeadersCopyWith<_BackendHeaders> get copyWith => throw _privateConstructorUsedError;
}

PaginationLink _$PaginationLinkFromJson(Map<String, dynamic> json) {
  return _PaginationLink.fromJson(json);
}

/// @nodoc
class _$PaginationLinkTearOff {
  const _$PaginationLinkTearOff();

  _PaginationLink call({required int maxPage}) {
    return _PaginationLink(
      maxPage: maxPage,
    );
  }

  PaginationLink fromJson(Map<String, Object?> json) {
    return PaginationLink.fromJson(json);
  }
}

/// @nodoc
const $PaginationLink = _$PaginationLinkTearOff();

/// @nodoc
mixin _$PaginationLink {
  int get maxPage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaginationLinkCopyWith<PaginationLink> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationLinkCopyWith<$Res> {
  factory $PaginationLinkCopyWith(PaginationLink value, $Res Function(PaginationLink) then) =
      _$PaginationLinkCopyWithImpl<$Res>;
  $Res call({int maxPage});
}

/// @nodoc
class _$PaginationLinkCopyWithImpl<$Res> implements $PaginationLinkCopyWith<$Res> {
  _$PaginationLinkCopyWithImpl(this._value, this._then);

  final PaginationLink _value;
  // ignore: unused_field
  final $Res Function(PaginationLink) _then;

  @override
  $Res call({
    Object? maxPage = freezed,
  }) {
    return _then(_value.copyWith(
      maxPage: maxPage == freezed
          ? _value.maxPage
          : maxPage // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$PaginationLinkCopyWith<$Res> implements $PaginationLinkCopyWith<$Res> {
  factory _$PaginationLinkCopyWith(_PaginationLink value, $Res Function(_PaginationLink) then) =
      __$PaginationLinkCopyWithImpl<$Res>;
  @override
  $Res call({int maxPage});
}

/// @nodoc
class __$PaginationLinkCopyWithImpl<$Res> extends _$PaginationLinkCopyWithImpl<$Res>
    implements _$PaginationLinkCopyWith<$Res> {
  __$PaginationLinkCopyWithImpl(_PaginationLink _value, $Res Function(_PaginationLink) _then)
      : super(_value, (v) => _then(v as _PaginationLink));

  @override
  _PaginationLink get _value => super._value as _PaginationLink;

  @override
  $Res call({
    Object? maxPage = freezed,
  }) {
    return _then(_PaginationLink(
      maxPage: maxPage == freezed
          ? _value.maxPage
          : maxPage // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_PaginationLink extends _PaginationLink {
  const _$_PaginationLink({required this.maxPage}) : super._();

  factory _$_PaginationLink.fromJson(Map<String, dynamic> json) => _$$_PaginationLinkFromJson(json);

  @override
  final int maxPage;

  @override
  String toString() {
    return 'PaginationLink(maxPage: $maxPage)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaginationLink &&
            const DeepCollectionEquality().equals(other.maxPage, maxPage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, const DeepCollectionEquality().hash(maxPage));

  @JsonKey(ignore: true)
  @override
  _$PaginationLinkCopyWith<_PaginationLink> get copyWith =>
      __$PaginationLinkCopyWithImpl<_PaginationLink>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PaginationLinkToJson(this);
  }
}

abstract class _PaginationLink extends PaginationLink {
  const factory _PaginationLink({required int maxPage}) = _$_PaginationLink;
  const _PaginationLink._() : super._();

  factory _PaginationLink.fromJson(Map<String, dynamic> json) = _$_PaginationLink.fromJson;

  @override
  int get maxPage;
  @override
  @JsonKey(ignore: true)
  _$PaginationLinkCopyWith<_PaginationLink> get copyWith => throw _privateConstructorUsedError;
}
