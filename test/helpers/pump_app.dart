// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
  }
}

Future<void> pumpRouterApp(
  WidgetTester tester,
  RootStackRouter router,
  StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider,
  AuthNotifier mockAuthNotifier,
) {
  return tester
      .pumpWidget(ProviderScope(
        overrides: [
          authNotifierProvider.overrideWithValue(
            mockAuthNotifier,
          ),
        ],
        child: MaterialApp.router(
          routeInformationParser: router.defaultRouteParser(),
          routerDelegate: router.delegate(),
        ),
      ))
      .then((_) => tester.pumpAndSettle());
}
