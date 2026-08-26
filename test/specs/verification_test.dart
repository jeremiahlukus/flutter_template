@Tags(['specs'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Makes the spec discipline unfakeable.
///
/// Every spec carries a **Verification** table mapping requirement IDs to the
/// tests that prove them. That table was the strongest thing in this repo and
/// the easiest to let rot: rename a test and the row still reads as proof. These
/// tests resolve the rows against the filesystem, so a stale row fails the suite
/// instead of quietly lying.
///
/// The rules are deliberately uneven, because the rows are. Structure and paths
/// are checked absolutely; rows that cite code rather than a test cannot be
/// checked and are instead **budgeted** — see `maxUncheckableRows`. That budget
/// is the anti-drift mechanism: adding a row nothing can verify means changing a
/// committed number, in the diff, on purpose.
void main() {
  final specs = _loadSpecs();

  test('there are specs to check at all', () {
    // Guards against the parser silently matching nothing, which would make
    // every test below vacuously green.
    expect(specs, isNotEmpty);
    expect(specs.length, greaterThan(20), reason: 'parser found too few specs');
  });

  group('structure', () {
    test('every requirement has a verification row, and vice versa', () {
      final problems = <String>[];
      for (final spec in specs) {
        final missing = spec.requirementIds.difference(spec.verifiedIds);
        final orphaned = spec.verifiedIds.difference(spec.requirementIds);
        if (missing.isNotEmpty) {
          problems.add(
            '${spec.path}: requirement(s) with no Verification row: '
            '${missing.toList()..sort()}',
          );
        }
        if (orphaned.isNotEmpty) {
          problems.add(
            '${spec.path}: Verification row(s) for requirements that do not '
            'exist: ${orphaned.toList()..sort()}',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('requirement ids are numbered from the spec they live in', () {
      final problems = <String>[];
      for (final spec in specs) {
        for (final id in spec.requirementIds) {
          if (!id.startsWith('${spec.number}-R')) {
            problems.add('${spec.path}: $id does not belong to ${spec.number}');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('rows resolve', () {
    test('every repo path named in a Verification row exists', () {
      // Catches the common rot: a test file renamed or moved while the row that
      // cites it stays put. Only tokens that actually look like repo paths are
      // checked — `ApiTimeouts` and `foo.dart` on their own are not paths.
      final problems = <String>[];
      for (final spec in specs) {
        for (final row in spec.rows) {
          for (final path in row.repoPaths) {
            if (!File(path).existsSync() && !Directory(path).existsSync()) {
              problems.add('${spec.path} ${row.id}: no such path `$path`');
            }
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('a named test exists in the file the row points at', () {
      // The strongest check here. When a row says
      //   `test/foo_test.dart` › `group` › `the name`
      // the innermost name must appear in that file.
      final problems = <String>[];
      for (final spec in specs) {
        for (final row in spec.rows) {
          final targets = row.searchableFiles;
          final name = row.innermostName;
          if (targets.isEmpty || name == null) continue;
          // Match the *whole* quoted name, not a substring: renaming
          // `bounced off the intro` to `bounced off the intro (v2)` must fail,
          // and a bare `contains` would let it pass as a prefix.
          //
          // A row may deliberately abbreviate a long name with a trailing
          // ellipsis, and those fall back to prefix matching.
          final truncated = name.endsWith('…');
          final needle = truncated ? name.substring(0, name.length - 1) : name;
          bool present(String file) {
            final source = File(file).readAsStringSync();
            // Strict only where the format is known. Dart and JS test names are
            // quoted literals, so demand the quotes — that is what catches a
            // rename to `…the intro (v2)`, which a bare substring would pass as
            // a prefix. YAML step names, rules blocks and prose citations have no
            // such shape, and demanding one produces false failures, which is
            // how a gate gets disabled.
            final quotable =
                !truncated && (file.endsWith('.dart') || file.endsWith('.js'));
            if (!quotable) return source.contains(needle);
            return source.contains("'$needle'") || source.contains('"$needle"');
          }

          final found = targets.any(present);
          if (!found) {
            problems.add(
              '${spec.path} ${row.id}: `$name` not found in '
              '${targets.join(' or ')}',
            );
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('honesty', () {
    test('an unproven requirement says why', () {
      // `—` is allowed: it is the honest answer while a spec is ahead of its
      // code. What is not allowed is a bare dash with no reason, which is
      // indistinguishable from an oversight.
      final problems = <String>[];
      for (final spec in specs) {
        for (final row in spec.rows) {
          if (!row.isUnproven) continue;
          if (row.text.replaceFirst('—', '').trim().isEmpty) {
            problems.add(
              '${spec.path} ${row.id}: unproven with no reason given. Write '
              '`— *(why, and what would prove it)*`, or name the test.',
            );
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('rows nothing can verify stay within budget', () {
      // Rows that cite code, a manual step, or a whole suite rather than one
      // named test. They are legitimate — forcing a fake test name would be
      // worse — but they are the hole in the discipline, so the count is pinned.
      //
      // The 23 here are, broadly: rows citing a constant or a code path rather
      // than a test (`ApiTimeouts`, `PushRegistrar._sync`), rows whose proof is
      // the whole suite running at all, and rows enforced by a type signature.
      //
      // **Raising this number is allowed and is meant to be deliberate.** If you
      // are raising it, satisfy yourself the row genuinely cannot name a test.
      // Lowering it never fails — turning one of these into a real test name is
      // the point.
      const maxUncheckableRows = 23;
      final uncheckable = <String>[];
      for (final spec in specs) {
        for (final row in spec.rows) {
          if (row.isUnproven) continue;
          if (row.resolvedTestFile == null || row.innermostName == null) {
            uncheckable.add('${spec.path} ${row.id}: ${row.text}');
          }
        }
      }
      expect(
        uncheckable.length,
        lessThanOrEqualTo(maxUncheckableRows),
        reason:
            '${uncheckable.length} row(s) name no verifiable test:\n'
            '${uncheckable.join('\n')}',
      );
    });
  });
}

// ---------------------------------------------------------------------------

/// A parsed spec: its requirement ids and its verification rows.
class Spec {
  Spec({
    required this.path,
    required this.number,
    required this.status,
    required this.requirementIds,
    required this.rows,
  });

  final String path;
  final String number;
  final String status;
  final Set<String> requirementIds;
  final List<VerificationRow> rows;

  Set<String> get verifiedIds => rows.map((r) => r.id).toSet();
}

/// One row of a Verification table.
class VerificationRow {
  VerificationRow({
    required this.id,
    required this.text,
    required this.repoPaths,
    required this.resolvedTestFile,
    required this.innermostName,
  });

  final String id;
  final String text;

  /// Tokens in the row that look like repo-relative paths.
  final List<String> repoPaths;

  /// The test file this row points at, with `…` resolved, or null.
  final String? resolvedTestFile;

  /// The last `› `-delimited backticked name, or null.
  final String? innermostName;

  /// Every existing file this row points at — the resolved one plus any others
  /// it names directly. A row citing two suites proves its name in either.
  List<String> get searchableFiles => {
    ?resolvedTestFile,
    ...repoPaths.where((p) => File(p).existsSync()),
  }.toList();

  bool get isUnproven => text.trimLeft().startsWith('—');
}

final _rowPattern = RegExp(
  r'^\|\s*(\d{4}-R\d+)\s*\|\s*(.+?)\s*\|\s*$',
  multiLine: true,
);
final _reqIdPattern = RegExp(r'^\|\s*(\d{4}-R\d+)\s*\|', multiLine: true);
// A repo path: has a slash and a file extension. Excludes bare `foo.dart`
// and `Class.member`, neither of which is a path.
final _repoPathPattern = RegExp(
  r'`([A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)+\.[A-Za-z0-9]+)`',
);
final _backtickedPattern = RegExp('`([^`]+)`');
// `…firestore…` — the tables' shorthand for "the file named earlier whose name
// contains this".
final _abbreviationPattern = RegExp('`…([^`…]+)…`');

List<Spec> _loadSpecs() {
  final dir = Directory('specs');
  if (!dir.existsSync()) return const [];

  final specs = <Spec>[];
  final entries = dir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final entry in entries) {
    final file = File('${entry.path}/spec.md');
    if (!file.existsSync()) continue;
    final body = file.readAsStringSync();
    final number = entry.path.split('/').last.substring(0, 4);

    final status =
        RegExp(r'\*\*Status:\*\*\s*(.+)').firstMatch(body)?.group(1)?.trim() ??
        'unknown';

    final requirements = _section(body, 'Requirements');
    final verification = _section(body, 'Verification');

    final rows = <VerificationRow>[];
    // Every repo path named so far in this spec, in order. `…foo…` resolves
    // against it, which is how the tables actually abbreviate: R4 saying
    // `…api_client…` switches the carried file, and the plain `…` rows after it
    // mean that file, not the one from R2.
    final namedSoFar = <String>[];
    String? carried;

    for (final match in _rowPattern.allMatches(verification)) {
      final id = match.group(1)!;
      final text = match.group(2)!.trim();

      final paths = _repoPathPattern
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toList();

      final abbreviations = _abbreviationPattern
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toList();
      final resolvedAbbreviations = <String>[
        for (final abbr in abbreviations)
          namedSoFar.lastWhere(
            (p) => p.split('/').last.contains(abbr),
            orElse: () => '',
          ),
      ]..removeWhere((p) => p.isEmpty);

      String? file;
      final firstBacktick = _backtickedPattern.firstMatch(text)?.group(1);
      if (firstBacktick == '…') {
        file = carried;
      } else if (resolvedAbbreviations.isNotEmpty) {
        file = carried = resolvedAbbreviations.first;
      } else {
        final existing = paths.firstWhere(
          (p) => File(p).existsSync(),
          orElse: () => '',
        );
        if (existing.isNotEmpty) file = carried = existing;
      }
      namedSoFar.addAll(paths.where((path) => File(path).existsSync()));

      // The innermost `› `-delimited name is the test name.
      String? name;
      if (text.contains('›')) {
        final tail = text.split('›').last.trim();
        final m = _backtickedPattern.firstMatch(tail);
        if (m != null && m.group(1) != '…') name = m.group(1);
      }

      rows.add(
        VerificationRow(
          id: id,
          text: text,
          repoPaths: [...paths, ...resolvedAbbreviations],
          resolvedTestFile: file,
          innermostName: name,
        ),
      );
    }

    specs.add(
      Spec(
        path: file.path,
        number: number,
        status: status,
        requirementIds: _reqIdPattern
            .allMatches(requirements)
            .map((m) => m.group(1)!)
            .toSet(),
        rows: rows,
      ),
    );
  }
  return specs;
}

/// The body of a `## <name>` section, up to the next `## `.
String _section(String body, String name) {
  final start = body.indexOf('\n## $name');
  if (start < 0) return '';
  final after = body.indexOf('\n## ', start + 1);
  return body.substring(start, after < 0 ? body.length : after);
}
