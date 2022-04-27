// Package imports:
import 'package:dartz/dartz.dart';

// Project imports:
import 'package:flutter_template/backend/core/domain/backend_failure.dart';
import 'package:flutter_template/backend/core/domain/user.dart';
import 'package:flutter_template/backend/core/infrastructure/user_local_service.dart';
import 'package:flutter_template/backend/core/infrastructure/user_remote_service.dart';
import 'package:flutter_template/core/infrastructure/network_exceptions.dart';

class UserRepository {
  final UserRemoteService _userRemoteService;
  final UserLocalService _userLocalService;
  UserRepository(this._userRemoteService, this._userLocalService);

  Future<Either<BackendFailure, User>> getUserPage() async {
    try {
      final userDetails = await _userRemoteService.getUserDetails();

      return right(
        await userDetails.when(
          noConnection: () => _userLocalService.getUser().then((value) => value.toDomain()),
          notModified: (maxPage) => _userLocalService.getUser().then((value) => value.toDomain()),
          withNewData: (data, maxPage) async {
            await _userLocalService.saveUser(data);
            return data.toDomain();
          },
        ),
      );
    } on RestApiException catch (e) {
      return left(BackendFailure.api(e.errorCode, null));
    }
  }
}
