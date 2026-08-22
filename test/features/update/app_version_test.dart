import 'package:flutter_template/src/features/update/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParse', () {
    test('parses a full version', () {
      expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
    });

    test('defaults missing components to zero', () {
      expect(AppVersion.tryParse('2'), const AppVersion(2, 0, 0));
      expect(AppVersion.tryParse('2.5'), const AppVersion(2, 5, 0));
    });

    test('ignores a build suffix', () {
      // `PackageInfo.version` is bare, but a store listing or config often
      // carries the build number.
      expect(AppVersion.tryParse('1.2.3+45'), const AppVersion(1, 2, 3));
    });

    test('tolerates a v prefix and surrounding whitespace', () {
      expect(AppVersion.tryParse('  v1.2.3 '), const AppVersion(1, 2, 3));
    });

    test('returns null rather than throwing on nonsense', () {
      // This value usually comes from a config document a human typed; one bad
      // string must not crash the app on launch.
      for (final raw in [
        null,
        '',
        'latest',
        '1.2.3.4',
        '1.two.3',
        '-1.0.0',
        '1..3',
      ]) {
        expect(AppVersion.tryParse(raw), isNull, reason: 'input: $raw');
      }
    });
  });

  group('ordering', () {
    test('compares major, then minor, then patch', () {
      expect(const AppVersion(1, 0, 0) < const AppVersion(2, 0, 0), isTrue);
      expect(const AppVersion(1, 2, 0) < const AppVersion(1, 3, 0), isTrue);
      expect(const AppVersion(1, 2, 3) < const AppVersion(1, 2, 4), isTrue);
    });

    test('does not compare components lexicographically', () {
      // The classic bug: '10' sorts before '9' as a string.
      expect(const AppVersion(1, 9, 0) < const AppVersion(1, 10, 0), isTrue);
      expect(const AppVersion(9, 0, 0) < const AppVersion(10, 0, 0), isTrue);
    });

    test('equal versions are neither less nor greater', () {
      const a = AppVersion(1, 2, 3);
      const b = AppVersion(1, 2, 3);

      expect(a < b, isFalse);
      expect(a >= b, isTrue);
      expect(a.compareTo(b), 0);
    });

    test('sorts a list correctly', () {
      final versions = [
        const AppVersion(1, 10, 0),
        const AppVersion(1, 2, 0),
        const AppVersion(2, 0, 0),
        const AppVersion(1, 2, 10),
      ]..sort();

      expect(versions.map((v) => v.toString()), [
        '1.2.0',
        '1.2.10',
        '1.10.0',
        '2.0.0',
      ]);
    });

    test('value equality and hashing', () {
      expect(const AppVersion(1, 2, 3), const AppVersion(1, 2, 3));
      expect(
        const AppVersion(1, 2, 3).hashCode,
        const AppVersion(1, 2, 3).hashCode,
      );
      expect(const AppVersion(1, 2, 3), isNot(const AppVersion(1, 2, 4)));
      expect(const AppVersion(1, 2, 3), isNot(equals('1.2.3')));
    });

    test('toString round-trips through tryParse', () {
      const version = AppVersion(3, 14, 15);
      expect(AppVersion.tryParse(version.toString()), version);
    });
  });

  group('UpdatePolicy.fromMap', () {
    test('reads all three fields', () {
      final policy = UpdatePolicy.fromMap(const {
        'minimumSupported': '1.0.0',
        'latest': '2.0.0',
        'storeUrl': 'https://example.com/app',
      });

      expect(policy.minimumSupported, const AppVersion(1, 0, 0));
      expect(policy.latest, const AppVersion(2, 0, 0));
      expect(policy.storeUrl, 'https://example.com/app');
    });

    test('an empty document yields an empty policy', () {
      final policy = UpdatePolicy.fromMap(const {});

      expect(policy.minimumSupported, isNull);
      expect(policy.latest, isNull);
      expect(policy.storeUrl, isNull);
    });

    test('unparseable versions become null, not an exception', () {
      final policy = UpdatePolicy.fromMap(const {
        'minimumSupported': 'soon',
        'latest': 42,
      });

      expect(policy.minimumSupported, isNull);
      expect(policy.latest, isNull);
    });

    test('a non-string storeUrl is ignored', () {
      expect(UpdatePolicy.fromMap(const {'storeUrl': 12}).storeUrl, isNull);
    });

    test('toString names the versions', () {
      final text = UpdatePolicy.fromMap(const {
        'minimumSupported': '1.0.0',
        'latest': '2.0.0',
      }).toString();

      expect(text, contains('1.0.0'));
      expect(text, contains('2.0.0'));
    });
  });

  group('requirementFor', () {
    const current = AppVersion(1, 5, 0);

    test('is none with no policy at all', () {
      expect(
        const UpdatePolicy().requirementFor(current),
        UpdateRequirement.none,
      );
    });

    test('is required below the floor', () {
      expect(
        const UpdatePolicy(
          minimumSupported: AppVersion(2, 0, 0),
        ).requirementFor(current),
        UpdateRequirement.required,
      );
    });

    test('is none exactly at the floor', () {
      expect(
        const UpdatePolicy(
          minimumSupported: AppVersion(1, 5, 0),
        ).requirementFor(current),
        UpdateRequirement.none,
      );
    });

    test('is optional below the latest but above the floor', () {
      expect(
        const UpdatePolicy(
          minimumSupported: AppVersion(1, 0, 0),
          latest: AppVersion(2, 0, 0),
        ).requirementFor(current),
        UpdateRequirement.optional,
      );
    });

    test('required wins over optional', () {
      expect(
        const UpdatePolicy(
          minimumSupported: AppVersion(2, 0, 0),
          latest: AppVersion(3, 0, 0),
        ).requirementFor(current),
        UpdateRequirement.required,
      );
    });

    test('is none when already on the latest', () {
      expect(
        const UpdatePolicy(latest: AppVersion(1, 5, 0)).requirementFor(current),
        UpdateRequirement.none,
      );
    });

    test('is none when ahead of the latest', () {
      // A dev build newer than the store listing must not be nagged.
      expect(
        const UpdatePolicy(latest: AppVersion(1, 0, 0)).requirementFor(current),
        UpdateRequirement.none,
      );
    });

    test('is none when the current version is unknown', () {
      // Failing open: an unreadable local version must never lock a user out.
      expect(
        const UpdatePolicy(
          minimumSupported: AppVersion(99, 0, 0),
        ).requirementFor(null),
        UpdateRequirement.none,
      );
    });
  });

  group('blocksUse', () {
    test('only a required update blocks', () {
      expect(UpdateRequirement.required.blocksUse, isTrue);
      expect(UpdateRequirement.optional.blocksUse, isFalse);
      expect(UpdateRequirement.none.blocksUse, isFalse);
    });
  });
}
