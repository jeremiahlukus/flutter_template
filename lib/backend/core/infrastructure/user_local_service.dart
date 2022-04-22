import 'package:flutter_template/backend/core/domain/user.dart';
import 'package:flutter_template/backend/core/infrastructure/backend_headers.dart';
import 'package:flutter_template/backend/core/infrastructure/user_dto.dart';
import 'package:flutter_template/core/infrastructure/sembast_database.dart';
import 'package:sembast/sembast.dart';

const key = 'user';

class UserLocalService {
  final SembastDatabase _sembastDatabase;
  final _store = stringMapStoreFactory.store('headers');

  UserLocalService(this._sembastDatabase);

  Future<void> saveUser(UserDTO dto) async {
    await _store.record(key).put(
          _sembastDatabase.instance,
          dto.toJson(),
        );
  }

  Future<UserDTO> getUser() async {
    final json = await _store.record(key).get(_sembastDatabase.instance) as Map<String, dynamic>;
    return UserDTO.fromJson(json);
  }

  Future<void> deleteUser() async {
    await _store.record(key).delete(_sembastDatabase.instance);
  }
}
