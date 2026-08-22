// A CLI tool's whole job is writing to stdout.
// ignore_for_file: avoid_print
import 'dart:io';

import 'coverage_report.dart';

/// Enforces a minimum line-coverage percentage from an lcov report.
///
/// Written in Dart rather than as a shell one-liner so the same command works on
/// every developer machine and on CI without depending on `lcov`/`genhtml`.
/// The parsing and threshold logic live in `coverage_report.dart`, which is unit
/// tested — this file is only argument handling and output.
///
/// Usage:
///   dart run tool/check_coverage.dart [--min 85] [--file coverage/lcov.info]
void main(List<String> args) {
  final minimum = double.tryParse(flagValue(args, '--min') ?? '85') ?? 85;
  final path = flagValue(args, '--file') ?? 'coverage/lcov.info';

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln(
      'No coverage report at $path.\n'
      'Run `flutter test --coverage` first.',
    );
    exit(2);
  }

  final report = CoverageReport.parse(file.readAsLinesSync());
  if (report.isEmpty) {
    stderr.writeln('$path contained no records. Was the run cut short?');
    exit(2);
  }

  print('Coverage by file (lowest first):');
  for (final entry in report.included) {
    print(
      '  ${entry.percent.toStringAsFixed(1).padLeft(6)}%  '
      '${entry.hit}/${entry.found}  ${entry.path}',
    );
  }

  final skipped = report.excluded.length;
  if (skipped > 0) print('\nExcluded $skipped generated/config file(s).');

  print(
    '\nTotal: ${report.percent.toStringAsFixed(2)}% '
    '(${report.linesHit}/${report.linesFound} lines)',
  );
  print('Required: ${minimum.toStringAsFixed(2)}%');

  if (!report.meets(minimum)) {
    final shortfall = (minimum - report.percent).toStringAsFixed(2);
    stderr.writeln('\n❌ Coverage is $shortfall points below the threshold.');

    final worst = report.worstThan(minimum).take(5);
    if (worst.isNotEmpty) {
      stderr.writeln('Least-covered files to look at first:');
      for (final entry in worst) {
        stderr.writeln(
          '  ${entry.percent.toStringAsFixed(1)}%  ${entry.path}',
        );
      }
    }
    exit(1);
  }

  print('\n✅ Coverage gate passed.');
}

/// Reads `--name value` or `--name=value`. Returns null when absent.
String? flagValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) return args[index + 1];

  for (final arg in args) {
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}
