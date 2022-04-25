// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'backend_failure.freezed.dart';

@freezed
class BackendFailure with _$BackendFailure {
  const BackendFailure._();
  const factory BackendFailure.api(int? errorCode, String? message) = _Api;
}
