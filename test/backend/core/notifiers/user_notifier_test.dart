// Package imports:
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/backend/core/domain/backend_failure.dart';
import 'package:flutter_template/backend/core/domain/user.dart';
import 'package:flutter_template/backend/core/infrastructure/user_repository.dart';
import 'package:flutter_template/backend/core/notifiers/user_notifier.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserNotifier', () {
    group('.getUserPage', () {
      test('sets state to UserState.loadFailure if UserRepository.getUserPage returns a BackendFailure', () async {
        final UserRepository mockUserRepository = MockUserRepository();

        when(mockUserRepository.getUserPage).thenAnswer(
          (invocation) => Future.value(left(const BackendFailure.api(400, 'message'))),
        );
        final userNotifier = UserNotifier(mockUserRepository);
        const defaultUser = User(name: 'name', avatarUrl: 'avatarUrl');
        // ignore: invalid_use_of_protected_member
        userNotifier.state = userNotifier.state.copyWith(user: defaultUser);

        await userNotifier.getUserPage();

        // ignore: invalid_use_of_protected_member
        final actualStateResult = userNotifier.state;

        final expectedStateResultMatcher = equals(
          const UserState.loadFailure(
            defaultUser,
            BackendFailure.api(400, 'message'),
          ),
        );

        expect(actualStateResult, expectedStateResultMatcher);
      });

      test('sets state to UserState.loadSuccess if UserRepository.getUserPage returns a User', () async {
        final UserRepository mockUserRepository = MockUserRepository();
        when(mockUserRepository.getUserPage).thenAnswer(
          (invocation) => Future.value(
            right(const User(name: 'name', avatarUrl: 'avatarUrl')),
          ),
        );

        final userNotifier = UserNotifier(mockUserRepository);

        await userNotifier.getUserPage();

        // ignore: invalid_use_of_protected_member
        final actualStateResult = userNotifier.state;

        final expectedStateResultMatcher = equals(
          const UserState.loadSuccess(
            User(name: 'name', avatarUrl: 'avatarUrl'),
          ),
        );

        expect(actualStateResult, expectedStateResultMatcher);
      });
    });
  });
}
