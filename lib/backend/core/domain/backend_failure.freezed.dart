// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'backend_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$BackendFailureTearOff {
  const _$BackendFailureTearOff();

  _Api api(int? errorCode, String? message) {
    return _Api(
      errorCode,
      message,
    );
  }
}

/// @nodoc
const $BackendFailure = _$BackendFailureTearOff();

/// @nodoc
mixin _$BackendFailure {
  int? get errorCode => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? errorCode, String? message) api,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int? errorCode, String? message)? api,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? errorCode, String? message)? api,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Api value) api,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Api value)? api,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Api value)? api,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackendFailureCopyWith<BackendFailure> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackendFailureCopyWith<$Res> {
  factory $BackendFailureCopyWith(BackendFailure value, $Res Function(BackendFailure) then) =
      _$BackendFailureCopyWithImpl<$Res>;
  $Res call({int? errorCode, String? message});
}

/// @nodoc
class _$BackendFailureCopyWithImpl<$Res> implements $BackendFailureCopyWith<$Res> {
  _$BackendFailureCopyWithImpl(this._value, this._then);

  final BackendFailure _value;
  // ignore: unused_field
  final $Res Function(BackendFailure) _then;

  @override
  $Res call({
    Object? errorCode = freezed,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      errorCode: errorCode == freezed
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as int?,
      message: message == freezed
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
abstract class _$ApiCopyWith<$Res> implements $BackendFailureCopyWith<$Res> {
  factory _$ApiCopyWith(_Api value, $Res Function(_Api) then) = __$ApiCopyWithImpl<$Res>;
  @override
  $Res call({int? errorCode, String? message});
}

/// @nodoc
class __$ApiCopyWithImpl<$Res> extends _$BackendFailureCopyWithImpl<$Res> implements _$ApiCopyWith<$Res> {
  __$ApiCopyWithImpl(_Api _value, $Res Function(_Api) _then) : super(_value, (v) => _then(v as _Api));

  @override
  _Api get _value => super._value as _Api;

  @override
  $Res call({
    Object? errorCode = freezed,
    Object? message = freezed,
  }) {
    return _then(_Api(
      errorCode == freezed
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as int?,
      message == freezed
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_Api extends _Api {
  const _$_Api(this.errorCode, this.message) : super._();

  @override
  final int? errorCode;
  @override
  final String? message;

  @override
  String toString() {
    return 'BackendFailure.api(errorCode: $errorCode, message: $message)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Api &&
            const DeepCollectionEquality().equals(other.errorCode, errorCode) &&
            const DeepCollectionEquality().equals(other.message, message));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(errorCode), const DeepCollectionEquality().hash(message));

  @JsonKey(ignore: true)
  @override
  _$ApiCopyWith<_Api> get copyWith => __$ApiCopyWithImpl<_Api>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? errorCode, String? message) api,
  }) {
    return api(errorCode, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int? errorCode, String? message)? api,
  }) {
    return api?.call(errorCode, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? errorCode, String? message)? api,
    required TResult orElse(),
  }) {
    if (api != null) {
      return api(errorCode, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Api value) api,
  }) {
    return api(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Api value)? api,
  }) {
    return api?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Api value)? api,
    required TResult orElse(),
  }) {
    if (api != null) {
      return api(this);
    }
    return orElse();
  }
}

abstract class _Api extends BackendFailure {
  const factory _Api(int? errorCode, String? message) = _$_Api;
  const _Api._() : super._();

  @override
  int? get errorCode;
  @override
  String? get message;
  @override
  @JsonKey(ignore: true)
  _$ApiCopyWith<_Api> get copyWith => throw _privateConstructorUsedError;
}
