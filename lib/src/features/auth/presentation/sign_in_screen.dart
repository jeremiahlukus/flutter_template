import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/l10n/l10n.dart';

/// Wraps `firebase_ui_auth`'s [SignInScreen] with this app's branding.
///
/// The FlutterFire UI widget is used as-is for the form itself — reimplementing
/// email/password validation, error copy, and the sign-up toggle is exactly the
/// kind of work a template should save you. The `auth` instance is injected from
/// [firebaseAuthProvider] so widget tests can drive it with `MockFirebaseAuth`
/// instead of a live project.
class TemplateSignInScreen extends ConsumerWidget {
  const TemplateSignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsServiceProvider);

    return SignInScreen(
      auth: ref.watch(firebaseAuthProvider),
      providers: [EmailAuthProvider()],
      headerBuilder: (context, constraints, shrinkOffset) => const _Header(),
      sideBuilder: (context, shrinkOffset) => const _Header(),
      subtitleBuilder: (context, action) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          action == AuthAction.signIn
              ? context.l10n.signInSubtitle
              : context.l10n.signUpSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      footerBuilder: (context, action) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          context.l10n.termsFooter,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        // firebase_ui_auth owns the credential flow, so these callbacks are the
        // only hook for app-side side effects. The bodies delegate to the static
        // handlers below: driving the real form in a test is impossible because
        // `firebase_auth_mocks` throws from `MockUserCredential
        // .additionalUserInfo`, which `firebase_ui_auth` reads on success.
        // Keeping the logic out of the closure keeps it testable anyway.
        AuthStateChangeAction<SignedIn>(
          (context, state) => recordSignIn(analytics, state.user?.uid),
        ),
        AuthStateChangeAction<UserCreated>(
          (context, state) =>
              recordSignUp(analytics, state.credential.user?.uid),
        ),
        ForgotPasswordAction((context, email) {
          analytics.logEvent('password_reset_opened');
          showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              child: ForgotPasswordScreen(
                auth: ref.read(firebaseAuthProvider),
                email: email,
                headerMaxExtent: 0,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Records a completed sign-in. Extracted so it is unit-testable.
  static void recordSignIn(AnalyticsService analytics, String? uid) {
    analytics
      ..logLogin('password')
      ..setUserId(uid);
  }

  /// Records a newly created account. Extracted so it is unit-testable.
  static void recordSignUp(AnalyticsService analytics, String? uid) {
    analytics
      ..logSignUp('password')
      ..setUserId(uid);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // `firebase_ui_auth` renders the header into a slot whose height it decides,
    // which on a short viewport is less than this content's natural size.
    // Scaling down is better than overflowing — and keeps the layout clean on
    // small phones and in the 800x600 widget-test window alike.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
