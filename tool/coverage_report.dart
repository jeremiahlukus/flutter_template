/// Line-coverage reporting from an lcov report.
///
/// Split out of `tool/check_coverage.dart` so the parser and the threshold rule
/// are unit-testable. The gate that guards the whole suite should not itself be
/// the one untested thing — a mis-parse here could let a bad report through
/// while CI stayed green.
library;

/// Files dropped before the total is computed. Keep this list short and
/// justified — every entry is a place the real number can drift while the gate
/// stays green.
const excludedPatterns = <String>[
  // Build output. Tested through the code that uses it.
  '.g.dart',
  '.freezed.dart',
  'generated_plugin_registrant.dart',

  // Placeholder that throws until `flutterfire configure` regenerates it.
  'firebase_options.dart',

  // `flutter gen-l10n` output, regenerated on every `pub get`. The ARB files are
  // the source, and ARB parity is gated separately in CI.
  'l10n/generated/',

  // Drift table declarations. The column getters (`text()()` and friends) are
  // evaluated by drift's *generator* at build time and never at runtime, so
  // they report 0% no matter how thoroughly the schema is tested. The schema
  // itself is covered in test/database/tables_test.dart.
  'database/tables.dart',
];

/// One `SF`/`LF`/`LH` record from an lcov report.
class FileCoverage {
  const FileCoverage(this.path, this.found, this.hit);

  final String path;

  /// Instrumented lines.
  final int found;

  /// Instrumented lines that were executed.
  final int hit;

  /// A file with no instrumented lines counts as fully covered rather than
  /// dragging the average down with a meaningless zero.
  double get percent => found == 0 ? 100 : hit / found * 100;

  bool get isExcluded => excludedPatterns.any(path.contains);

  @override
  String toString() => 'FileCoverage($path, $hit/$found)';
}

/// Aggregate of the files that count.
class CoverageReport {
  const CoverageReport(this.files);

  /// Parses the `SF`/`LF`/`LH` triples of an lcov report.
  ///
  /// Unknown lines are ignored, and a record without a terminating
  /// `end_of_record` is dropped — a truncated report should not be silently
  /// treated as a passing one.
  factory CoverageReport.parse(List<String> lines) {
    final results = <FileCoverage>[];
    String? path;
    var found = 0;
    var hit = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('SF:')) {
        path = trimmed.substring(3).trim();
        found = 0;
        hit = 0;
      } else if (trimmed.startsWith('LF:')) {
        found = int.tryParse(trimmed.substring(3).trim()) ?? 0;
      } else if (trimmed.startsWith('LH:')) {
        hit = int.tryParse(trimmed.substring(3).trim()) ?? 0;
      } else if (trimmed == 'end_of_record' && path != null) {
        results.add(FileCoverage(path, found, hit));
        path = null;
      }
    }
    return CoverageReport(results);
  }

  final List<FileCoverage> files;

  /// Files that count towards the total, least-covered first.
  List<FileCoverage> get included =>
      files.where((f) => !f.isExcluded).toList()
        ..sort((a, b) => a.percent.compareTo(b.percent));

  List<FileCoverage> get excluded => files.where((f) => f.isExcluded).toList();

  int get linesFound => included.fold(0, (sum, f) => sum + f.found);

  int get linesHit => included.fold(0, (sum, f) => sum + f.hit);

  /// An empty report is 100%, not 0% — but [isEmpty] is how a caller tells the
  /// difference, because "no records" almost always means a broken run.
  double get percent => linesFound == 0 ? 100 : linesHit / linesFound * 100;

  bool get isEmpty => files.isEmpty;

  /// True when [percent] clears [minimum].
  ///
  /// Compared with a small epsilon so a report that is exactly at the threshold
  /// passes despite floating-point representation.
  bool meets(double minimum) => percent + 1e-9 >= minimum;

  List<FileCoverage> worstThan(double minimum) =>
      included.where((f) => f.percent < minimum).toList();
}
