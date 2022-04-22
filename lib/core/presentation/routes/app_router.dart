// Package imports:
import 'package:auto_route/auto_route.dart';

// Project imports:
import 'package:flutter_template/auth/presentation/authorization_page.dart';
import 'package:flutter_template/auth/presentation/sign_in_page.dart';
import 'package:flutter_template/backend/dashboard/presentation/dashboard_page.dart';
import 'package:flutter_template/splash/presentation/splash_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute<dynamic>(page: SplashPage, initial: true),
    AutoRoute<dynamic>(page: SignInPage, path: '/sign-in'),
    AutoRoute<dynamic>(page: AuthorizationPage, path: '/auth'),
    AutoRoute<dynamic>(page: DashboardPage, path: '/dashboard'),
  ],
)
class $AppRouter {}
