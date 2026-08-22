import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paths and names', () {
    test('every route has a non-empty path and name', () {
      for (final route in AppRoute.values) {
        expect(route.path, isNotEmpty, reason: '${route.name} path');
        expect(route.name, isNotEmpty, reason: '${route.name} name');
      }
    });

    test('names are unique', () {
      final names = AppRoute.values.map((r) => r.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('paths are unique', () {
      final paths = AppRoute.values.map((r) => r.path).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('notes is the root', () {
      expect(AppRoute.notes.path, '/');
    });

    test('the editor path carries an id parameter', () {
      expect(AppRoute.noteEditor.path, contains(':id'));
    });
  });

  group('paths', () {
    test('enumerates every route', () {
      // The allow-list for externally-supplied routes — a deep link or a push
      // payload. Untrusted input must never be navigated to unchecked.
      expect(AppRoute.paths, hasLength(AppRoute.values.length));
      for (final route in AppRoute.values) {
        expect(AppRoute.paths, contains(route.path));
      }
    });

    test('excludes a path that is not a declared route', () {
      expect(AppRoute.paths, isNot(contains('/admin')));
      expect(AppRoute.paths, isNot(contains('/notes/abc')));
    });
  });

  group('isPublic', () {
    test('sign-in is public', () {
      expect(AppRoute.isPublic(AppRoute.signIn.path), isTrue);
    });

    test('a sub-path of a public route is public', () {
      expect(AppRoute.isPublic('/sign-in/forgot-password'), isTrue);
    });

    test('the root is not public', () {
      expect(AppRoute.isPublic('/'), isFalse);
    });

    test('profile is not public', () {
      expect(AppRoute.isPublic('/profile'), isFalse);
    });

    test('a path that merely starts with the same letters is not public', () {
      // '/sign-in-secretly' must not inherit '/sign-in''s public status.
      expect(AppRoute.isPublic('/sign-in-secretly'), isFalse);
    });

    test('onboarding is public', () {
      expect(AppRoute.isPublic(AppRoute.onboarding.path), isTrue);
    });

    test('only sign-in and onboarding are reachable without an account', () {
      final public = AppRoute.values
          .where((r) => AppRoute.isPublic(r.path))
          .toSet();
      expect(public, {AppRoute.signIn, AppRoute.onboarding});
    });
  });
}
