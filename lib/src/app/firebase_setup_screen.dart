import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/l10n/l10n.dart';

/// Shown instead of the app when Firebase could not be initialised.
///
/// A template that dies on launch is a bad first impression and a confusing one
/// — the real cause (`lib/firebase_options.dart` is still the placeholder) is
/// nowhere on screen. This renders the fix instead.
///
/// Deliberately self-contained: no Riverpod, no providers, no Firebase. It has
/// to work in exactly the situation where everything else does not.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocales.supported,
      home: FirebaseSetupScreen(error: error),
    );
  }
}

/// The body of [FirebaseSetupApp]. Separated so it can be pumped directly.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({this.error, super.key});

  final Object? error;

  /// The commands that fix it, in order.
  static const commands = <String>[
    'dart pub global activate flutterfire_cli',
    'flutterfire configure',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.setupTitle,
                    key: const ValueKey('setup_title'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.setupBody, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.setupStepsHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final command in commands) _CommandRow(command: command),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.setupRestartHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          l10n.setupChecklistHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    // Collapsed by default: the instructions above are what the
                    // reader needs, and the raw error is noise until they don't.
                    ExpansionTile(
                      key: const ValueKey('setup_error_details'),
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        l10n.setupDetails,
                        style: theme.textTheme.titleSmall,
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            '$error',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.smAll,
        ),
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                command,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            IconButton(
              key: ValueKey('copy_$command'),
              tooltip: context.l10n.copy,
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: command));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.setupCopied)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
