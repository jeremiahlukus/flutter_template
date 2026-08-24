// A CLI tool's whole job is writing to stdout.
// ignore_for_file: avoid_print
import 'dart:io';

/// Renames the package, then repairs what the rename breaks.
///
/// `sed`-ing `flutter_template` to something else is only *most* of the job, and
/// the missing part fails the analyzer gate immediately:
///
/// `flutter_template` sorts between `package:flutter_riverpod/` and
/// `package:flutter_test/`, so nearly every import block in the project is
/// ordered around that position. Rename it to anything that sorts elsewhere and
/// `directives_ordering` fires on file after file — dozens of infos, which
/// `--fatal-infos` counts as a failure. A fresh fork's first experience is then
/// a wall of analyzer errors in code it has not written, and the obvious
/// diagnosis ("the gate is too strict") is the wrong one.
///
/// So this does the rename *and* the re-sort, in one step:
///
/// ```sh
/// dart run tool/rename_package.dart my_app
/// dart run tool/rename_package.dart my_app --dry-run
/// ```
///
/// It deliberately does **not** touch the Drift database name
/// (`AppDatabase.databaseName`). If you are replacing an app that is already
/// shipped, that name must stay as it was or every user's local data becomes
/// unreachable. The tool prints a reminder either way.
Future<void> main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('-')).toList();
  final dryRun = args.contains('--dry-run');

  if (positional.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/rename_package.dart <new_package_name> [--dry-run]',
    );
    exit(64);
  }

  final newName = positional.single;
  const oldName = 'flutter_template';

  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(newName)) {
    stderr.writeln(
      'Invalid package name "$newName".\n'
      'Dart package names are lower_snake_case, starting with a letter.',
    );
    exit(64);
  }
  if (newName == oldName) {
    stderr.writeln('That is already the package name.');
    exit(64);
  }

  final targets = _filesContaining(oldName);
  if (targets.isEmpty) {
    stderr.writeln(
      'Found no occurrences of "$oldName". Has the package already been '
      'renamed?',
    );
    exit(1);
  }

  print('Renaming $oldName → $newName in ${targets.length} file(s).');
  if (dryRun) {
    for (final file in targets) {
      final hits = RegExp(oldName).allMatches(file.readAsStringSync()).length;
      print('  $hits\t${file.path}');
    }
    print('\nDry run: nothing written.');
    return;
  }

  for (final file in targets) {
    final before = file.readAsStringSync();
    final renamed = before.replaceAll(oldName, newName);

    // Length is a cheap integrity check on the blanket replace: the only thing
    // that may change is the name itself. An early version of this silently
    // dropped an `ignore_for_file` comment, which is the kind of thing you find
    // weeks later.
    final hits = RegExp(oldName).allMatches(before).length;
    final expected = before.length + hits * (newName.length - oldName.length);
    if (renamed.length != expected) {
      stderr.writeln(
        'Refusing to write ${file.path}: replacement changed more than the '
        'package name. Nothing further was written.',
      );
      exit(1);
    }

    // Then undo the rename on lines that opted out. The Drift database name is
    // the reason this exists: it is a string literal that happens to contain the
    // package name, and renaming it repoints a shipped app at a new empty file,
    // making every user's local data unreachable with no error. The worst thing
    // this tool could do, and the least visible.
    file.writeAsStringSync(
      _restoreMarkedLines(renamed, oldName: oldName, newName: newName),
    );
  }

  print('\nRe-sorting imports — this is the step a plain sed misses.');
  await _run('dart', ['fix', '--apply', '--code=directives_ordering']);
  await _run('dart', ['format', 'lib', 'test', 'tool']);

  print('''

Done. Two things the rename did NOT do, on purpose:

  1. AppDatabase.databaseName is still '$oldName' — deliberately preserved.
     Replacing an app that is already shipped? Set it to that app's existing
     database name, and carry its schemaVersion and migrations forward. Getting
     this wrong points the app at a new empty file: every user's data is still on
     disk with nothing referencing it, and there is no error.
     Greenfield? Change it to '$newName', and update the expectation in
     test/database/app_database_test.dart.

  2. The bundle id / application id is unchanged. See task.md Milestone 0.

Now run: flutter analyze --fatal-infos --fatal-warnings && flutter test
''');
}

/// Marks a line the rename must leave alone.
///
/// A fork can add this to its own lines. It exists because the package name also
/// appears in places where it is *not* a package reference — the Drift database
/// file name being the one that matters — and those cannot be distinguished by
/// pattern.
const keepMarker = '// keep-on-rename';

/// Reverts [newName] to [oldName] on every line carrying [keepMarker].
///
/// Done as a second pass rather than by skipping those lines during the replace,
/// so the integrity check still sees a clean whole-file substitution.
String _restoreMarkedLines(
  String source, {
  required String oldName,
  required String newName,
}) => source
    .split('\n')
    .map(
      (line) =>
          line.contains(keepMarker) ? line.replaceAll(newName, oldName) : line,
    )
    .join('\n');

/// Every tracked text file containing [needle].
List<File> _filesContaining(String needle) {
  const roots = ['lib', 'test', 'tool', 'test_rules'];
  const alsoCheck = ['pubspec.yaml', 'l10n.yaml', 'README.md', 'CLAUDE.md'];

  final files = <File>[
    for (final root in roots)
      if (Directory(root).existsSync())
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => _isText(f.path) && !_isVendored(f.path)),
    for (final path in alsoCheck)
      if (File(path).existsSync()) File(path),
  ];

  return files.where((f) {
    try {
      return f.readAsStringSync().contains(needle);
    } on FileSystemException {
      return false;
    }
  }).toList();
}

/// Machine-generated or third-party trees. `test_rules/node_modules` is the one
/// that matters: it is thousands of files, and a dependency that happens to
/// mention this package's name would be rewritten inside its own source.
bool _isVendored(String path) => const [
  'node_modules',
  '.dart_tool',
  'build',
  'coverage',
  '.git',
].any((dir) => path.split(Platform.pathSeparator).contains(dir));

bool _isText(String path) => const [
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.md',
  '.arb',
].any(path.endsWith);

Future<void> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    stderr
      ..writeln('$executable ${arguments.join(' ')} failed:')
      ..writeln(result.stdout)
      ..writeln(result.stderr);
    exit(result.exitCode);
  }
}
