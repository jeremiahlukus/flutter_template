import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_template/auth/presentation/authorization_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../test/auth/presentation/authorization_page_test.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewExample', () {
    testWidgets('fill the email and password text fields',
        (WidgetTester tester) async {
      final mockObserver = MockNavigatorObserver();

      final OnAuthorizationCodeRedirectAttemptCallback
          mockOnAuthorizationCodeRedirectAttemptCallback =
          MockOnAuthorizationCodeRedirectAttemptCallback();

      when(mockOnAuthorizationCodeRedirectAttemptCallback.call)
          .thenReturn((_) {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthorizationPage(
            authorizationUrl: Uri.parse(
              'https://mdbootstrap.com/docs/standard/extended/login/#section-basic-example',
            ),
            onAuthorizationCodeRedirectAttempt:
                mockOnAuthorizationCodeRedirectAttemptCallback(),
            onWebViewCreatedJsString: """
          document.getElementById('form2Example1').value='example.com'
          document.getElementsByClassName("form-label")[0].innerHTML = "";
          document.getElementById('form2Example2').value='password'
          document.getElementsByClassName("form-label")[1].innerHTML = "";
          document.getElementsByClassName("btn btn-primary btn-block mb-4")[0].click();
          """,
          ),
          navigatorObservers: [mockObserver],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WebView), findsOneWidget);
    });
  });
}
