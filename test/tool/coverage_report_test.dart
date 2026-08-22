import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_report.dart';

/// The gate that guards the whole suite should not itself be the one untested
/// thing — a mis-parse here could let a bad report through while CI stayed green.
void main() {
  List<String> record(String path, {required int found, required int hit}) => [
    'SF:$path',
    'DA:1,1',
    'LF:$found',
    'LH:$hit',
    'end_of_record',
  ];

  group('parse', () {
    test('reads a single record', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 10, hit: 8),
      );

      expect(report.files, hasLength(1));
      expect(report.files.single.path, 'lib/a.dart');
      expect(report.files.single.found, 10);
      expect(report.files.single.hit, 8);
    });

    test('reads several records', () {
      final report = CoverageReport.parse([
        ...record('lib/a.dart', found: 10, hit: 10),
        ...record('lib/b.dart', found: 10, hit: 5),
      ]);

      expect(report.files, hasLength(2));
    });

    test('ignores unrecognised lines', () {
      final report = CoverageReport.parse([
        'TN:',
        'SF:lib/a.dart',
        'FNF:3',
        'FNH:2',
        'BRDA:1,0,0,1',
        'LF:4',
        'LH:4',
        'end_of_record',
      ]);

      expect(report.files.single.found, 4);
    });

    test('tolerates leading whitespace', () {
      final report = CoverageReport.parse([
        '  SF:lib/a.dart',
        '  LF:2',
        '  LH:1',
        '  end_of_record',
      ]);

      expect(report.files.single.hit, 1);
    });

    test('drops a record with no end_of_record', () {
      // A truncated report must not be silently treated as a passing one.
      final report = CoverageReport.parse([
        'SF:lib/a.dart',
        'LF:10',
        'LH:0',
      ]);

      expect(report.files, isEmpty);
      expect(report.isEmpty, isTrue);
    });

    test('an empty input yields an empty report', () {
      expect(CoverageReport.parse([]).isEmpty, isTrue);
    });

    test('a non-numeric count degrades to zero rather than throwing', () {
      final report = CoverageReport.parse([
        'SF:lib/a.dart',
        'LF:not-a-number',
        'LH:also-not',
        'end_of_record',
      ]);

      expect(report.files.single.found, 0);
      expect(report.files.single.hit, 0);
    });

    test('resets counters between records', () {
      // A record missing LF/LH must not inherit the previous file's numbers.
      final report = CoverageReport.parse([
        ...record('lib/a.dart', found: 10, hit: 10),
        'SF:lib/b.dart',
        'end_of_record',
      ]);

      expect(report.files.last.found, 0);
    });
  });

  group('exclusions', () {
    test('drops generated Drift and Freezed output', () {
      for (final path in [
        'lib/src/database/app_database.g.dart',
        'lib/src/models/thing.freezed.dart',
        'lib/generated_plugin_registrant.dart',
      ]) {
        expect(
          const FileCoverage('', 0, 0).isExcluded,
          isFalse,
          reason: 'sanity: an empty path is not excluded',
        );
        expect(
          FileCoverage(path, 10, 0).isExcluded,
          isTrue,
          reason: '$path should be excluded',
        );
      }
    });

    test('drops the placeholder Firebase config', () {
      expect(
        const FileCoverage('lib/firebase_options.dart', 5, 0).isExcluded,
        isTrue,
      );
    });

    test('drops gen-l10n output', () {
      expect(
        const FileCoverage(
          'lib/src/l10n/generated/app_localizations.dart',
          500,
          0,
        ).isExcluded,
        isTrue,
      );
    });

    test('drops Drift table declarations', () {
      expect(
        const FileCoverage('lib/src/database/tables.dart', 11, 0).isExcluded,
        isTrue,
      );
    });

    test('keeps ordinary source files', () {
      expect(
        const FileCoverage(
          'lib/src/features/notes/note.dart',
          50,
          50,
        ).isExcluded,
        isFalse,
      );
    });

    test('an excluded file does not affect the total', () {
      final report = CoverageReport.parse([
        ...record('lib/a.dart', found: 10, hit: 10),
        ...record('lib/src/database/app_database.g.dart', found: 900, hit: 0),
      ]);

      expect(report.percent, 100);
      expect(report.excluded, hasLength(1));
      expect(report.linesFound, 10);
    });

    test('every exclusion pattern is non-empty', () {
      // An empty pattern would match every path and silently disable the gate.
      for (final pattern in excludedPatterns) {
        expect(pattern, isNotEmpty);
      }
    });
  });

  group('percent', () {
    test('is the ratio of hit to found', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 4, hit: 3),
      );

      expect(report.percent, 75);
    });

    test('sums across files rather than averaging them', () {
      // A 100%-covered one-line file must not offset a 0%-covered large one.
      final report = CoverageReport.parse([
        ...record('lib/a.dart', found: 1, hit: 1),
        ...record('lib/b.dart', found: 99, hit: 0),
      ]);

      expect(report.percent, closeTo(1, 0.001));
    });

    test('a file with no instrumented lines counts as covered', () {
      expect(const FileCoverage('lib/a.dart', 0, 0).percent, 100);
    });

    test('a report with no instrumented lines is 100%, but flagged empty', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 0, hit: 0),
      );

      expect(report.percent, 100);
      expect(report.isEmpty, isFalse, reason: 'it does have a record');
    });
  });

  group('meets', () {
    test('passes above the threshold', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 100, hit: 90),
      );

      expect(report.meets(85), isTrue);
    });

    test('fails below the threshold', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 100, hit: 80),
      );

      expect(report.meets(85), isFalse);
    });

    test('passes exactly at the threshold', () {
      // Floating-point representation must not fail a report that is exactly at
      // the limit.
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 3, hit: 1),
      );

      expect(report.meets(100 / 3), isTrue);
    });

    test('a zero threshold always passes', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 10, hit: 0),
      );

      expect(report.meets(0), isTrue);
    });
  });

  group('ordering and diagnostics', () {
    test('included is sorted least-covered first', () {
      final report = CoverageReport.parse([
        ...record('lib/good.dart', found: 10, hit: 10),
        ...record('lib/bad.dart', found: 10, hit: 1),
        ...record('lib/mid.dart', found: 10, hit: 5),
      ]);

      expect(
        report.included.map((f) => f.path),
        ['lib/bad.dart', 'lib/mid.dart', 'lib/good.dart'],
      );
    });

    test('worstThan names only the files under the threshold', () {
      final report = CoverageReport.parse([
        ...record('lib/good.dart', found: 10, hit: 10),
        ...record('lib/bad.dart', found: 10, hit: 1),
      ]);

      expect(report.worstThan(85).map((f) => f.path), ['lib/bad.dart']);
    });

    test('worstThan is empty when everything passes', () {
      final report = CoverageReport.parse(
        record('lib/a.dart', found: 10, hit: 10),
      );

      expect(report.worstThan(85), isEmpty);
    });

    test('toString names the path and counts', () {
      final text = const FileCoverage('lib/a.dart', 10, 8).toString();

      expect(text, contains('lib/a.dart'));
      expect(text, contains('8/10'));
    });
  });

  group('against the real report', () {
    test('the committed exclusion list matches the documented one', () {
      // README and spec 0007 both enumerate these; a silent addition here would
      // make the published number and the enforced number disagree.
      expect(excludedPatterns, hasLength(6));
      expect(excludedPatterns, contains('firebase_options.dart'));
      expect(excludedPatterns, contains('l10n/generated/'));
      expect(excludedPatterns, contains('database/tables.dart'));
    });
  });
}
