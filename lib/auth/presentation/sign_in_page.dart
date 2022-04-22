// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/core/presentation/routes/app_router.gr.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({Key? key}) : super(key: key);

  static const signInButtonKey = ValueKey('signInButtonKey');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: FaIcon(
                      FontAwesomeIcons.gitkraken,
                      size: 150,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  AutoSizeText(
                    'Welcome to \nFlutter Template',
                    style: Theme.of(context).textTheme.headline3,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  ElevatedButton(
                    key: signInButtonKey,
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).signIn(
                        (authorizationUrl) {
                          final completer = Completer<Uri>();
                          AutoRouter.of(context).push(
                            AuthorizationRoute(
                              authorizationUrl: authorizationUrl,
                              onAuthorizationCodeRedirectAttempt: completer.complete,
                            ),
                          );
                          return completer.future;
                        },
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                    ),
                    child: const Text('Sign In'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
