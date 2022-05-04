// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/webapp_authenticator.dart';

class AuthorizationPage extends StatefulWidget {
  const AuthorizationPage({
    Key? key,
    required this.authorizationUrl,
    required this.onAuthorizationCodeRedirectAttempt,
    this.onWebViewCreatedJsString,
  }) : super(key: key);

  static const backButtonKey = ValueKey('backButton');

  final Uri authorizationUrl;
  final void Function(Uri redirectUri) onAuthorizationCodeRedirectAttempt;
  final String? onWebViewCreatedJsString;

  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebView(
              javascriptMode: JavascriptMode.unrestricted,
              initialUrl: widget.authorizationUrl.toString(),
              onWebViewCreated: (controller) {
                controller.clearCache();
                CookieManager().clearCookies();
                if (widget.onWebViewCreatedJsString != null) {
                  controller.runJavascript(widget.onWebViewCreatedJsString!);
                }
              },
              navigationDelegate: (navReq) async {
                if (navReq.url.startsWith(WebAppAuthenticator.redirectUrl().toString())) {
                  widget.onAuthorizationCodeRedirectAttempt(
                    Uri.parse(navReq.url),
                  );
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: const Text(''), // You can add title here
                leading: IconButton(
                  key: AuthorizationPage.backButtonKey,
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                backgroundColor: Colors.white.withOpacity(0.1), //You can make this transparent
                elevation: 0, //No shadow
              ),
            ),
          ],
        ),
      ),
    );
  }
}
