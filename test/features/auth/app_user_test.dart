import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_template/src/features/auth/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppUser user({String? displayName, String? email}) => AppUser(
    id: 'u1',
    email: email,
    displayName: displayName,
    photoUrl: null,
    isEmailVerified: false,
    isAnonymous: false,
  );

  group('fromFirebase', () {
    test('copies every field across', () {
      final mock = MockUser(
        uid: 'abc',
        email: 'a@b.co',
        displayName: 'Grace',
        photoURL: 'https://example.com/p.png',
      );

      final result = AppUser.fromFirebase(mock);

      expect(result.id, 'abc');
      expect(result.email, 'a@b.co');
      expect(result.displayName, 'Grace');
      expect(result.photoUrl, 'https://example.com/p.png');
      expect(result.isEmailVerified, isTrue);
      expect(result.isAnonymous, isFalse);
    });

    test('handles an anonymous user with no email', () {
      final result = AppUser.fromFirebase(
        MockUser(uid: 'anon', isAnonymous: true),
      );

      expect(result.email, anyOf(isNull, isEmpty));
      expect(result.isAnonymous, isTrue);
    });
  });

  group('label', () {
    test('prefers the display name', () {
      expect(user(displayName: 'Ada', email: 'a@b.co').label, 'Ada');
    });

    test('trims the display name', () {
      expect(user(displayName: '  Ada  ').label, 'Ada');
    });

    test('falls back to email when the name is blank', () {
      expect(user(displayName: '   ', email: 'a@b.co').label, 'a@b.co');
    });

    test('falls back to email when the name is null', () {
      expect(user(email: 'a@b.co').label, 'a@b.co');
    });

    test('falls back to Guest when both are missing', () {
      expect(user().label, 'Guest');
    });

    test('falls back to Guest when both are blank', () {
      expect(user(displayName: ' ', email: '  ').label, 'Guest');
    });
  });

  group('initials', () {
    test('takes the first letter of the first two words', () {
      expect(user(displayName: 'Ada Lovelace').initials, 'AL');
    });

    test('uses one letter for a single-word name', () {
      expect(user(displayName: 'Ada').initials, 'A');
    });

    test('splits an email on its separators', () {
      expect(user(email: 'ada.lovelace@example.com').initials, 'AL');
    });

    test('uppercases lowercase input', () {
      expect(user(displayName: 'ada lovelace').initials, 'AL');
    });

    test('ignores extra words beyond the first two', () {
      expect(user(displayName: 'Ada Byron Lovelace').initials, 'AB');
    });

    test('collapses repeated separators', () {
      expect(user(displayName: 'Ada   Lovelace').initials, 'AL');
    });

    test('returns ? when there is nothing to abbreviate', () {
      expect(
        const AppUser(
          id: 'u',
          email: '@',
          displayName: '@',
          photoUrl: null,
          isEmailVerified: false,
          isAnonymous: true,
        ).initials,
        '?',
      );
    });

    test('Guest fallback yields G', () {
      expect(user().initials, 'G');
    });
  });

  group('copyWith', () {
    test('replaces only what is passed', () {
      final original = user(displayName: 'Ada', email: 'a@b.co');
      final updated = original.copyWith(displayName: 'Grace');

      expect(updated.displayName, 'Grace');
      expect(updated.email, 'a@b.co');
      expect(updated.id, original.id);
    });

    test('keeps the original when nothing is passed', () {
      final original = user(displayName: 'Ada');
      expect(original.copyWith(), original);
    });

    test('can update the verified flag and photo', () {
      final updated = user().copyWith(
        isEmailVerified: true,
        photoUrl: 'https://x/y.png',
      );
      expect(updated.isEmailVerified, isTrue);
      expect(updated.photoUrl, 'https://x/y.png');
    });
  });

  group('value equality', () {
    test('equal fields compare equal and hash alike', () {
      expect(user(displayName: 'Ada'), user(displayName: 'Ada'));
      expect(
        user(displayName: 'Ada').hashCode,
        user(displayName: 'Ada').hashCode,
      );
    });

    test('differing fields compare unequal', () {
      expect(user(displayName: 'Ada'), isNot(user(displayName: 'Grace')));
    });

    test('is not equal to an unrelated type', () {
      expect(user(), isNot(equals('not a user')));
    });

    test('toString names the id and email', () {
      expect(user(email: 'a@b.co').toString(), contains('u1'));
      expect(user(email: 'a@b.co').toString(), contains('a@b.co'));
    });
  });
}
