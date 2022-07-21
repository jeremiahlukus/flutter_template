// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:alchemist/alchemist.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Project imports:
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/backend/core/domain/user.dart';
import 'package:flutter_template/backend/core/infrastructure/user_repository.dart';
import 'package:flutter_template/backend/core/notifiers/user_notifier.dart';
import 'package:flutter_template/backend/core/shared/providers.dart';
import 'package:flutter_template/backend/dashboard/presentation/dashboard_page.dart';
import '../../../utils/device.dart';
import '../../../utils/golden_test_device_scenario.dart';

class MockUserRepository extends Mock implements UserRepository {}

class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier(UserRepository userRepository) : super(userRepository);

  @override
  Future<void> getUserPage() async {
    state = const UserState.loadSuccess(
      User(name: 'Jon Doe', avatarUrl: 'www.example.com/avatarUrl'),
    );
    return;
  }
}

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockDio extends Mock implements Dio {}

void main() {
  group('DashboardPage', () {
    testWidgets("shows a CircleAvatar widget if the user's avatar url is not empty", (tester) async {
      final UserNotifier fakeUserNotifier = FakeUserNotifier(MockUserRepository());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userNotifierProvider.overrideWithValue(
              fakeUserNotifier,
            ),
          ],
          child: const MaterialApp(
            home: DashboardPage(),
          ),
        ),
      );

      await tester.pump(Duration.zero);

      final circleAvatarFinder = find.byType(CircleAvatar);

      expect(circleAvatarFinder, findsOneWidget);
    });

    testWidgets("clicking on Sign Out button triggers provided AuthNotifier's signOut method", (tester) async {
      final UserNotifier fakeUserNotifier = FakeUserNotifier(MockUserRepository());
      final AuthNotifier mockAuthNotifier = MockAuthNotifier();

      when(mockAuthNotifier.signOut).thenAnswer((_) => Future.value());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userNotifierProvider.overrideWithValue(
              fakeUserNotifier,
            ),
            authNotifierProvider.overrideWithValue(
              mockAuthNotifier,
            ),
          ],
          child: const MaterialApp(
            home: DashboardPage(),
          ),
        ),
      );

      await tester.pump(Duration.zero);

      final signOutButtonFinder = find.byKey(DashboardPageState.signOutButtonKey);

      await tester.tap(signOutButtonFinder);

      await tester.pump();

      verify(mockAuthNotifier.signOut).called(1);
    });
  });

  group('DashboardPage Golden Test', () {
    final UserNotifier fakeUserNotifier = FakeUserNotifier(MockUserRepository());

    Widget buildWidgetUnderTest() => ProviderScope(
          overrides: [
            userNotifierProvider.overrideWithValue(
              fakeUserNotifier,
            ),
          ],
          child: const MaterialApp(
            home: DashboardPage(),
          ),
        );
    goldenTest(
      'renders correctly on mobile',
      fileName: 'DashboardPage',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestDeviceScenario(
            device: Device.smallPhone,
            name: 'golden test SignInPage on small phone',
            builder: buildWidgetUnderTest,
          ),
          GoldenTestDeviceScenario(
            device: Device.tabletLandscape,
            name: 'golden test SignInPage on tablet landscape',
            builder: buildWidgetUnderTest,
          ),
          GoldenTestDeviceScenario(
            device: Device.tabletPortrait,
            name: 'golden test SignInPage on tablet Portrait',
            builder: buildWidgetUnderTest,
          ),
          GoldenTestDeviceScenario(
            name: 'golden test SignInPage on iphone11',
            builder: buildWidgetUnderTest,
          ),
        ],
      ),
    );
  });
}
