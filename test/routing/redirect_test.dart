import 'package:flutter_template/src/routing/app_router.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// The complete truth table for the route guard.
///
/// This is the cheapest place to prove that a signed-out visitor cannot reach a
/// protected screen, so it is covered exhaustively here rather than through
/// slower widget tests.
void main() {
  String? redirect({
    required String location,
    required bool signedIn,
    bool authResolved = true,
    bool onboardingCompleted = true,
  }) => resolveRedirect(
    location: location,
    signedIn: signedIn,
    authResolved: authResolved,
    onboardingCompleted: onboardingCompleted,
  );

  group('onboarding', () {
    test('takes precedence over the auth guard', () {
      // 0014-R5. The intro explains the app, so it comes before being asked to
      // create an account. A signed-out user heading for a protected route is
      // sent to the intro, *not* to sign-in — which is what "precedence" means
      // here, and is the whole reason the check sits above the auth branch.
      expect(
        redirect(
          location: AppRoute.notes.path,
          signedIn: false,
          onboardingCompleted: false,
        ),
        AppRoute.onboarding.path,
      );

      // Even the public sign-in route defers to it.
      expect(
        redirect(
          location: AppRoute.signIn.path,
          signedIn: false,
          onboardingCompleted: false,
        ),
        AppRoute.onboarding.path,
      );

      // And a signed-in user who has not seen it still sees it.
      expect(
        redirect(
          location: AppRoute.notes.path,
          signedIn: true,
          onboardingCompleted: false,
        ),
        AppRoute.onboarding.path,
      );

      // The intro itself is reachable while incomplete, or the guard would loop.
      expect(
        redirect(
          location: AppRoute.onboarding.path,
          signedIn: false,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });

    test('a completed user is bounced off the intro', () {
      // 0014-R6. Unreachable once finished, including by typing the URL — and
      // where you land depends on whether you are signed in.
      expect(
        redirect(location: AppRoute.onboarding.path, signedIn: false),
        AppRoute.signIn.path,
      );
      expect(
        redirect(location: AppRoute.onboarding.path, signedIn: true),
        AppRoute.notes.path,
      );
    });

    test('an unresolved auth state still wins over the intro', () {
      // Ordering detail worth pinning: redirecting before Firebase has reported
      // would flash the intro at a returning user mid-launch.
      expect(
        redirect(
          location: AppRoute.notes.path,
          signedIn: false,
          authResolved: false,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });
  });

  group('while auth is still resolving', () {
    test('never redirects, whatever the location', () {
      for (final route in AppRoute.values) {
        expect(
          redirect(location: route.path, signedIn: false, authResolved: false),
          isNull,
          reason: '${route.name} should not bounce before auth is known',
        );
      }
    });

    test('does not redirect a signed-in user either', () {
      expect(
        redirect(location: '/', signedIn: true, authResolved: false),
        isNull,
      );
    });
  });

  group('signed out', () {
    test('is sent to sign-in from the root', () {
      expect(redirect(location: '/', signedIn: false), '/sign-in');
    });

    test('is sent to sign-in from every protected route', () {
      final protected = AppRoute.values.where(
        (r) => !AppRoute.isPublic(r.path),
      );

      for (final route in protected) {
        expect(
          redirect(location: route.path, signedIn: false),
          AppRoute.signIn.path,
          reason: '${route.name} must be guarded',
        );
      }
    });

    test('is sent to sign-in from a deep note URL', () {
      expect(redirect(location: '/notes/abc123', signedIn: false), '/sign-in');
    });

    test('is left alone on the sign-in screen', () {
      expect(redirect(location: '/sign-in', signedIn: false), isNull);
    });

    test('is left alone on a sign-in sub-route', () {
      expect(
        redirect(location: '/sign-in/forgot-password', signedIn: false),
        isNull,
      );
    });
  });

  group('signed in', () {
    test('is bounced off the sign-in screen to the notes list', () {
      expect(redirect(location: '/sign-in', signedIn: true), '/');
    });

    test('is bounced off a sign-in sub-route too', () {
      expect(
        redirect(location: '/sign-in/forgot-password', signedIn: true),
        '/',
      );
    });

    test('is left alone on every protected route', () {
      final protected = AppRoute.values.where(
        (r) => !AppRoute.isPublic(r.path),
      );

      for (final route in protected) {
        expect(
          redirect(location: route.path, signedIn: true),
          isNull,
          reason: '${route.name} should be reachable',
        );
      }
    });

    test('is left alone on a deep note URL', () {
      expect(redirect(location: '/notes/abc123', signedIn: true), isNull);
    });

    test('is left alone on an unknown path so the error page can render', () {
      expect(redirect(location: '/does-not-exist', signedIn: true), isNull);
    });
  });

  test('redirects converge — the result of a redirect is never redirected', () {
    for (final signedIn in [true, false]) {
      for (final route in AppRoute.values) {
        final first = redirect(location: route.path, signedIn: signedIn);
        if (first == null) continue;

        expect(
          redirect(location: first, signedIn: signedIn),
          isNull,
          reason: 'redirecting $signedIn from ${route.path} to $first loops',
        );
      }
    }
  });
}
