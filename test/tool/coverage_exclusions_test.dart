// The justification rule for coverage exclusions, checked rather than trusted.
//
// Every entry in `excludedPatterns` is a place the real coverage number can
// drift while the gate stays green, so 0007-R3 requires each one to say why it
// is there. That was previously verified by reading the file — which is exactly
// the kind of row Principle II exists to eliminate.
@Tags(['architecture'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The source lines of the `excludedPatterns` list body.
List<String> _exclusionBlock() {
  final source = File('tool/coverage_report.dart').readAsLinesSync();
  final start = source.indexWhere((l) => l.contains('excludedPatterns'));
  expect(start, isNot(-1), reason: 'excludedPatterns is gone from the tool');
  final end = source.indexWhere((l) => l.trim() == '];', start);
  expect(end, isNot(-1), reason: 'excludedPatterns list is unterminated');
  return source.sublist(start + 1, end);
}

void main() {
  test('every coverage exclusion carries a written justification', () {
    // A comment may cover a run of related entries — grouping is fine, silence
    // is not. So each literal must have some comment above it in the block.
    final literal = RegExp(r"""^\s*['"]""");
    final unjustified = <String>[];
    var justification = '';

    for (final line in _exclusionBlock()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//')) {
        justification = trimmed;
        continue;
      }
      if (!literal.hasMatch(line)) continue;
      if (justification.isEmpty) unjustified.add(trimmed);
    }

    expect(
      unjustified,
      isEmpty,
      reason:
          'A bare exclusion is a hole in the coverage number that nobody can '
          'audit. Say why, above it:\n${unjustified.join('\n')}',
    );
  });

  test('the exclusion list is not silently empty', () {
    // A cleared list would pass the rule above by vacuity.
    final entries = _exclusionBlock()
        .where((l) => RegExp(r"""^\s*['"]""").hasMatch(l))
        .length;
    expect(entries, greaterThan(0));
  });
}
