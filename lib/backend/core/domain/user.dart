// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const User._();
  const factory User({
    required String name,
    required String avatarUrl,
  }) = _User;

  String avatarUrlOverride(String size) {
    return avatarUrl.replaceAll('&size=48', '&size=$size');
  }
}
