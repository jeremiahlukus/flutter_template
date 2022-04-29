// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:flutter_template/backend/core/infrastructure/user_dto.dart';
import 'package:flutter_template/core/infrastructure/sembast_database.dart';

class UserLocalService {
  final SembastDatabase _sembastDatabase;

  @visibleForTesting
  static final store = stringMapStoreFactory.store('headers');

  @visibleForTesting
  static const key = 'user';

  UserLocalService(this._sembastDatabase);

  Future<void> saveUser(UserDTO dto) async {
    await store.record(key).put(
          _sembastDatabase.instance,
          dto.toJson(),
        );
  }

  Future<UserDTO> getUser() async {
    // ignore: cast_nullable_to_non_nullable
    final json = await store.record(key).get(_sembastDatabase.instance) as Map<String, dynamic>;
    return UserDTO.fromJson(json);
  }

  Future<void> deleteUser() async {
    await store.record(key).delete(_sembastDatabase.instance);
  }
}
