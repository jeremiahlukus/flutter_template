// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:flutter_template/auth/presentation/authorization_page.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

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
  group('AuthorizationPage', () {
    testWidgets('shows a WebView', (tester) async {
      final mockObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthorizationPage(
            authorizationUrl: Uri(scheme: ''),
            onAuthorizationCodeRedirectAttempt: (Uri _) => <String, String>{},
          ),
          navigatorObservers: [mockObserver],
        ),
      );

      await tester.pump(Duration.zero);

      final backButtonFinder = find.byType(WebView);

      expect(backButtonFinder, findsOneWidget);
    });

    testWidgets('clicking on the back button pops the navigation', (tester) async {
      final mockObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthorizationPage(
            authorizationUrl: Uri(scheme: ''),
            onAuthorizationCodeRedirectAttempt: (Uri _) => <String, String>{},
          ),
          navigatorObservers: [mockObserver],
        ),
      );

      await tester.pump(Duration.zero);

      final backButtonFinder = find.byKey(AuthorizationPage.backButtonKey);

      await tester.tap(backButtonFinder);

      await tester.pump();

      verify(() => mockObserver.didPop(any(), any()));
    });
  });
}
