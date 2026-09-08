// Architectural invariants that no single unit test can express.
//
// These are the rules in CLAUDE.md that used to be verified by reading the
// code — a spec row that said "the whole file" or "enforced by signature" and
// so proved nothing. Each test here resolves one of those rows against the
// filesystem instead, which is the point of Principle II.
@Tags(['architecture'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `.dart` file under [dir], as (path, source) pairs.
List<(String, String)> _dartFiles(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => (f.path, f.readAsStringSync()))
      .toList();
}

/// The `import '...'` targets of [source].
List<String> _imports(String source) => RegExp(
  r"""^import\s+'([^']+)'""",
  multiLine: true,
).allMatches(source).map((m) => m.group(1)!).toList();

void main() {
  group('the test suite needs no Firebase project and no network', () {
    test('every Firebase singleton is reached only through a provider', () {
      // The seam the whole suite depends on. A direct `.instance` call in
      // feature code cannot be faked, so the test that touches it would need a
      // real Firebase app — which is what keeps this suite offline.
      final singleton = RegExp(
        'Firebase(Auth|Firestore|Storage|Crashlytics|Analytics|Messaging)'
        r'\.instance',
      );
      final offenders = <String>[];

      for (final (path, source) in _dartFiles('lib')) {
        final lines = source.split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (!singleton.hasMatch(lines[i])) continue;
          // Allowed in the central provider file, or in any provider factory —
          // `(ref) => X.instance` is already behind the seam.
          final centralised = path.endsWith('firebase_providers.dart');
          final inFactory = RegExp(r'\(\s*ref\s*\)\s*=>').hasMatch(lines[i]);
          if (centralised || inFactory) continue;
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'A Firebase singleton outside a provider cannot be faked, so the '
            'suite would need a real project. Put it behind a provider:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('QA tooling is not reachable from the app', () {
    test('nothing in lib imports the tooling in tool/', () {
      final offenders = <String>[];
      for (final (path, source) in _dartFiles('lib')) {
        for (final target in _imports(source)) {
          if (target.contains('tool/') || target.endsWith('main_dev.dart')) {
            offenders.add('$path -> $target');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'tool/ is QA scaffolding and must never ship in the app:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('the coverage gate stays dependency-free', () {
    test('the coverage tool needs nothing beyond the Dart SDK', () {
      // It runs in CI before `pub get` has necessarily resolved anything, so a
      // single `package:` import would break the gate that guards everything
      // else. Relative imports are fine — they ship with the tool.
      final offenders = <String>[];
      for (final file in [
        'tool/check_coverage.dart',
        'tool/coverage_report.dart',
      ]) {
        final source = File(file).readAsStringSync();
        for (final target in _imports(source)) {
          final isSdk = target.startsWith('dart:');
          final isRelative = !target.contains(':');
          if (!isSdk && !isRelative) offenders.add('$file -> $target');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('design values come from tokens', () {
    test('no inline spacing, radii, or durations in presentation code', () {
      // The rebrand promise: changing one enum value restyles the app. An
      // inline `8` is a value no token can reach.
      final inline = RegExp(
        r'EdgeInsets\.(all|symmetric|only)\([^)]*\b\d+(\.\d+)?\b'
        r'|SizedBox\(\s*(height|width):\s*\d'
        r'|BorderRadius\.circular\(\s*\d'
        r'|Duration\(\s*(milliseconds|seconds):\s*\d',
      );
      final offenders = <String>[];

      for (final (path, source) in _dartFiles('lib')) {
        // The theme *defines* the numbers; presentation must only name them.
        if (path.contains('/app/theme/')) continue;
        // Network timeouts and retry backoff are behaviour, not design.
        if (path.contains('/core/network/')) continue;
        final lines = source.split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (inline.hasMatch(lines[i])) {
            offenders.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Use AppSpacing / AppRadius / AppDurations instead of a literal:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('goldens can be run and excluded selectively', () {
    test('every golden test declares the golden tag', () {
      // CI runs `--exclude-tags golden` because goldens are platform-pinned.
      // An untagged golden runs on Linux and fails on a font it does not have.
      final untagged = <String>[];
      for (final (path, source) in _dartFiles('test/goldens')) {
        if (!source.contains("@Tags(['golden'])")) untagged.add(path);
      }
      expect(
        untagged,
        isEmpty,
        reason:
            'An untagged golden cannot be excluded, so it runs everywhere:\n'
            '${untagged.join('\n')}',
      );
    });

    test('the golden tag is declared in dart_test.yaml', () {
      // An undeclared tag still works but warns on every run, and the warning
      // is how a typo'd tag hides.
      expect(File('dart_test.yaml').readAsStringSync(), contains('golden:'));
    });
  });
}
