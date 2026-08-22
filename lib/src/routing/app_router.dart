import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/widgets/app_states.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/auth/presentation/profile_screen.dart';
import 'package:flutter_template/src/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_template/src/features/notes/presentation/note_editor_screen.dart';
import 'package:flutter_template/src/features/notes/presentation/notes_screen.dart';
import 'package:flutter_template/src/features/onboarding/onboarding_providers.dart';
import 'package:flutter_template/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_template/src/features/push/push_providers.dart';
import 'package:flutter_template/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/routing/analytics_observer.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Decides where a navigation attempt should actually land.
///
/// Extracted as a pure function because route guards are the single easiest
/// place to ship a security bug, and this way the whole truth table is covered
/// by fast unit tests instead of widget tests.
///
/// Order matters: onboarding is checked *before* auth, because the intro
/// explains the app and should be seen before being asked to create an account.
///
/// Returns null to allow the requested [location].
@visibleForTesting
String? resolveRedirect({
  required String location,
  required bool signedIn,
  required bool authResolved,
  bool onboardingCompleted = true,
}) {
  // Until Firebase has reported a state, sending anyone anywhere would either
  // flash the sign-in screen at a returning user or leak a protected screen.
  if (!authResolved) return null;

  final isOnboarding = location == AppRoute.onboarding.path;

  if (!onboardingCompleted) {
    return isOnboarding ? null : AppRoute.onboarding.path;
  }
  // Finished the intro: never show it again, even by direct navigation.
  if (isOnboarding) {
    return signedIn ? AppRoute.notes.path : AppRoute.signIn.path;
  }

  final isPublic = AppRoute.isPublic(location);

  if (!signedIn && !isPublic) return AppRoute.signIn.path;
  if (signedIn && isPublic) return AppRoute.notes.path;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router listens to a Listenable, Riverpod exposes a stream: bridge them
  // with a notifier that pings on every auth transition.
  final refresh = ValueNotifier<Object?>(null);
  ref
    ..listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (_, next) => refresh.value = next.value,
      fireImmediately: true,
    )
    // Finishing onboarding must re-run the guard too, or the user stays on the
    // intro until something else happens to trigger a refresh.
    ..listen<bool>(
      onboardingCompletedProvider,
      (_, next) => refresh.value = Object(),
    )
    ..onDispose(refresh.dispose);

  // Assigned below, read by the push listener. The listener only ever fires
  // after this function returns, so it is safe — and it lets the push layer stay
  // ignorant of routing while the router stays ignorant of push.
  late final GoRouter router;

  ref.listen<AsyncValue<String>>(pushRouteProvider, (_, next) {
    final route = next.value;
    if (route == null) return;
    // A tap on a notification that launched a terminated app arrives here too,
    // via `PushService.initialMessage`, which resolves after the first frame.
    if (AppRoute.paths.contains(route)) {
      router.go(route);
    } else {
      AppLogger.instance.w('Ignoring unknown push route: $route');
    }
  });

  // Assigned rather than returned directly: the push listener above closes over
  // `router`, so it has to exist as a named variable.
  // ignore: join_return_with_assignment
  router = GoRouter(
    initialLocation: AppRoute.notes.path,
    refreshListenable: refresh,
    observers: [
      AnalyticsNavigatorObserver(ref.read(analyticsServiceProvider)),
    ],
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        signedIn: auth.value != null,
        authResolved: !auth.isLoading,
        onboardingCompleted: ref.read(onboardingCompletedProvider),
      );
    },
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn.path,
        name: AppRoute.signIn.name,
        builder: (context, state) => const TemplateSignInScreen(),
      ),
      GoRoute(
        path: AppRoute.notes.path,
        name: AppRoute.notes.name,
        builder: (context, state) => const NotesScreen(),
        routes: [
          GoRoute(
            path: 'notes/:id',
            name: AppRoute.noteEditor.name,
            builder: (context, state) => NoteEditorScreen(
              noteId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'profile',
            name: AppRoute.profile.name,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
  );

  // The local cannot be inlined: the push listener above closes over `router`,
  // so it has to exist as a named variable.
  return router;
});

/// Shown for an unmatched or malformed route.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({required this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pageNotFound)),
      body: AppEmptyState(
        icon: Icons.explore_off_outlined,
        title: context.l10n.pageNotFound,
        message: error?.toString() ?? context.l10n.pageNotFoundBody,
        action: FilledButton(
          key: const ValueKey('back_to_notes_button'),
          onPressed: () => context.goNamed(AppRoute.notes.name),
          child: Text(context.l10n.backToNotes),
        ),
      ),
    );
  }
}
