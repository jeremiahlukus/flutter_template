// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/backend/core/domain/backend_failure.dart';
import 'package:flutter_template/backend/core/domain/user.dart';
import 'package:flutter_template/backend/core/infrastructure/user_repository.dart';

part 'user_notifier.freezed.dart';

@freezed
class UserState with _$UserState {
  const UserState._();
  // for easy access of repos, makes it present on all states and available on the state directly
  const factory UserState.initial(User user) = _Initial;
  const factory UserState.loadInProgress(User user) = _LoadInProgress;
  const factory UserState.loadSuccess(
    User user,
  ) = _LoadSuccess;
  // return list of objects because we still want to show the prev loaded pages on load of next page
  const factory UserState.loadFailure(
    User user,
    BackendFailure failure,
  ) = _LoadFailure;
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _userRepository;

  UserNotifier(this._userRepository)
      : super(
          const UserState.initial(
            User(
              name: '',
              avatarUrl: '',
            ),
          ),
        );

  Future<void> getUserPage() async {
    state = UserState.loadInProgress(state.user);
    final failureOrUser = await _userRepository.getUserPage();
    state = failureOrUser.fold((l) => UserState.loadFailure(state.user, l), (r) {
      return UserState.loadSuccess(r);
    });
  }
}
