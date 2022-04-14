// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dartz/dartz.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Project imports:
import 'package:flutter_template/auth/notifiers/auth_notifier.dart';
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/core/presentation/routes/app_router.gr.dart';

final initializationProvider = FutureProvider<Unit>(
  (ref) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.checkAndUpdateAuthStatus();
    return unit;
  },
);

class AppWidget extends ConsumerWidget {
  AppWidget({Key? key}) : super(key: key);
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen(initializationProvider, (previous, next) {})
      ..listen<AuthState>(authNotifierProvider, (previous, next) {
        next.maybeMap(
          orElse: () {},
          authenticated: (_) {
            _appRouter.pushAndPopUntil(
              const CounterRoute(),
              predicate: (route) => false,
            );
          },
          unauthenticated: (_) {
            _appRouter.pushAndPopUntil(
              const SignInRoute(),
              predicate: (route) => false,
            );
          },
        );
      });
    return MaterialApp.router(
      builder: (context, widget) => ResponsiveWrapper.builder(
        ClampingScrollWrapper.builder(context, widget!),
        defaultScale: true,
        minWidth: 480,
        defaultName: MOBILE,
        breakpoints: const [
          ResponsiveBreakpoint.resize(350, name: MOBILE),
          ResponsiveBreakpoint.autoScale(600, name: TABLET),
          ResponsiveBreakpoint.resize(800, name: DESKTOP),
          ResponsiveBreakpoint.autoScale(1700, name: 'XL'),
        ],
      ),
      theme: FlexThemeData.light(scheme: FlexScheme.materialHc),
      title: 'Flutter Template',
      routerDelegate: _appRouter.delegate(),
      routeInformationParser: _appRouter.defaultRouteParser(),
    );
  }
}
