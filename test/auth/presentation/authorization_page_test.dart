// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';
import 'package:flutter_template/auth/presentation/authorization_page.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockWebViewController extends Mock implements WebViewController {}

class MockNavigationRequest extends Mock implements NavigationRequest {}

class MockOnAuthorizationCodeRedirectAttemptCallback extends Mock
    implements OnAuthorizationCodeRedirectAttemptCallback {}

// ignore: one_member_abstracts
abstract class OnAuthorizationCodeRedirectAttemptCallback {
  void Function(Uri) call();
}

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

    testWidgets('WebViewController clears cached when webview is created', (tester) async {
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

      final webView = backButtonFinder.evaluate().single.widget as WebView;

      final mockWebViewController = MockWebViewController();

      when(mockWebViewController.clearCache).thenAnswer((invocation) => Future.value());

      webView.onWebViewCreated?.call(mockWebViewController);

      verify(mockWebViewController.clearCache).called(1);
    });

    testWidgets(
        "the onAuthorizationCodeRedirectAttempt callback is called when the WebView's navigationDelegate method is called",
        (tester) async {
      final mockObserver = MockNavigatorObserver();

      final OnAuthorizationCodeRedirectAttemptCallback mockOnAuthorizationCodeRedirectAttemptCallback =
          MockOnAuthorizationCodeRedirectAttemptCallback();

      when(mockOnAuthorizationCodeRedirectAttemptCallback.call).thenReturn((_) {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthorizationPage(
            authorizationUrl: Uri(scheme: ''),
            onAuthorizationCodeRedirectAttempt: mockOnAuthorizationCodeRedirectAttemptCallback(),
          ),
          navigatorObservers: [mockObserver],
        ),
      );

      await tester.pump(Duration.zero);

      final backButtonFinder = find.byType(WebView);

      final webView = backButtonFinder.evaluate().single.widget as WebView;

      final mockWebViewController = MockWebViewController();

      when(mockWebViewController.clearCache).thenAnswer((invocation) => Future.value());

      final NavigationRequest mockNavigationRequest = MockNavigationRequest();

      when(() => mockNavigationRequest.url).thenReturn('${WebAppAuthenticator.redirectUrl()}');

      webView.navigationDelegate?.call(mockNavigationRequest);

      // ignore: unnecessary_lambdas
      verify(() => mockOnAuthorizationCodeRedirectAttemptCallback()).called(1);
    });

    testWidgets('sets WebView.platform to SurfaceAndroidWebView when the running Platform is Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final mockObserver = MockNavigatorObserver();

      final OnAuthorizationCodeRedirectAttemptCallback mockOnAuthorizationCodeRedirectAttemptCallback =
          MockOnAuthorizationCodeRedirectAttemptCallback();

      when(mockOnAuthorizationCodeRedirectAttemptCallback.call).thenReturn((_) {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthorizationPage(
            authorizationUrl: Uri(scheme: ''),
            onAuthorizationCodeRedirectAttempt: mockOnAuthorizationCodeRedirectAttemptCallback(),
          ),
          navigatorObservers: [mockObserver],
        ),
      );

      await tester.pump(Duration.zero);

      final webViewIsSurfaceAndroidWebView = isA<SurfaceAndroidWebView>();

      expect(WebView.platform, webViewIsSurfaceAndroidWebView);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
