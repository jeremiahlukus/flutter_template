// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:alchemist/alchemist.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';
import 'package:flutter_template/auth/presentation/authorization_page.dart';
import 'package:flutter_template/auth/presentation/sign_in_page.dart';
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/core/presentation/routes/app_router.gr.dart';
import '../../utils/device.dart';
import '../../utils/golden_test_device_scenario.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockWebAppAuthenticator extends Mock implements WebAppAuthenticator {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) {
          return Container();
        },
      ),
    );
  });
  group('SignInPage', () {
    testWidgets('contains the "Welcome to Flutter Template" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInPage(),
        ),
      );

      await tester.pump(Duration.zero);

      final welcomeTextFinder = find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'Welcome to \nFlutter Template',
      );

      expect(welcomeTextFinder, findsOneWidget);
    });

    testWidgets("clicking on Sign In button triggers provided AuthNotifier's signIn method", (tester) async {
      final AuthNotifier mockAuthNotifier = MockAuthNotifier();

      when(() => mockAuthNotifier.signIn(any())).thenAnswer((_) => Future.value());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWithValue(
              mockAuthNotifier,
            ),
          ],
          child: const MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      await tester.pump(Duration.zero);

      final signInButtonFinder = find.byKey(SignInPage.signInButtonKey);

      await tester.tap(signInButtonFinder);

      await tester.pump();

      verify(() => mockAuthNotifier.signIn(any())).called(1);
    });
    testWidgets('clicking on Sign In button navigates to AuthorizationPage', (tester) async {
      final mockWebAppAuthenticator = MockWebAppAuthenticator();

      when(mockWebAppAuthenticator.getAuthorizationUrl).thenAnswer((invocation) => Uri(path: '/test'));

      final mockAuthNotifier = AuthNotifier(mockWebAppAuthenticator);

      final mockObserver = MockNavigatorObserver();

      final router = AppRouter();

      // ignore: unawaited_futures, cascade_invocations
      router.push(const SignInRoute());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWithValue(
              mockAuthNotifier,
            ),
          ],
          child: MaterialApp.router(
            routerDelegate: AutoRouterDelegate(
              router,
              navigatorObservers: () => [mockObserver],
            ),
            routeInformationParser: AppRouter().defaultRouteParser(),
          ),
        ),
      );

      await tester.pump(Duration.zero);

      final signInButtonFinder = find.byKey(SignInPage.signInButtonKey);

      await tester.tap(signInButtonFinder);

      await tester.pumpAndSettle();

      final authorizationPageFinder = find.byType(AuthorizationPage);

      expect(authorizationPageFinder, findsOneWidget);
    });
  });

  group('SignInPage Golden Test', () {
    Widget buildWidgetUnderTest() => const MaterialApp(
          home: Scaffold(
            body: SignInPage(),
          ),
        );
    goldenTest(
      'renders correctly on mobile',
      fileName: 'SignInPage',
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
