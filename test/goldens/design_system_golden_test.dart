@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_template/src/app/theme/app_semantic_colors.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Visual regression tests for the design system.
///
/// These are the only tests that can catch "the theme still compiles but now
/// looks wrong" — a component theme dropped, a contrast regression, a radius
/// that stopped applying. Unit tests assert values; only a golden asserts the
/// result.
///
/// **Platform-pinned.** Font rasterisation differs between macOS and Linux, so
/// goldens generated on one will fail on the other. CI runs this file on macOS
/// only, and the main test job excludes the `golden` tag. Regenerate with:
///
/// ```sh
/// flutter test --tags golden --update-goldens
/// ```
void main() {
  /// Renders every themed component on one surface.
  ///
  /// One wide golden per theme rather than one per component: a component theme
  /// regression almost always shows up next to its neighbours, and 6 brands × 2
  /// brightnesses × N components would be unreviewable.
  Widget showcase(ThemeData theme) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Builder(
      builder: (context) {
        final colors = AppSemanticColors.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Showcase'),
            actions: const [
              IconButton(
                onPressed: null,
                icon: Icon(Icons.sync),
                tooltip: 'Sync',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Text('Headline', style: theme.textTheme.headlineSmall),
                Text('Title', style: theme.textTheme.titleMedium),
                Text(
                  'Body copy that runs long enough to show the line height '
                  'the type scale sets.',
                  style: theme.textTheme.bodyMedium,
                ),
                Text('Caption', style: theme.textTheme.bodySmall),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'Hint',
                  ),
                ),
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
                Card(
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Text('Card', style: theme.textTheme.titleMedium),
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    const Chip(label: Text('Chip')),
                    Chip(
                      label: const Text('Success'),
                      backgroundColor: colors.successContainer,
                      labelStyle: TextStyle(
                        color: colors.onSuccessContainer,
                      ),
                    ),
                    Chip(
                      label: const Text('Warning'),
                      backgroundColor: colors.warningContainer,
                      labelStyle: TextStyle(
                        color: colors.onWarningContainer,
                      ),
                    ),
                    Chip(
                      label: const Text('Info'),
                      backgroundColor: colors.infoContainer,
                      labelStyle: TextStyle(color: colors.onInfoContainer),
                    ),
                  ],
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.note_outlined),
                  title: Text('List tile'),
                  subtitle: Text('Subtitle'),
                ),
                const LinearProgressIndicator(value: 0.4),
              ],
            ),
          ),
        );
      },
    ),
  );

  Future<void> pumpShowcase(WidgetTester tester, ThemeData theme) async {
    tester.view
      ..physicalSize = const Size(600, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(showcase(theme));
    await tester.pumpAndSettle();
  }

  group('brand themes', () {
    for (final brand in AppBrand.values) {
      testWidgets('${brand.name} light', (tester) async {
        await pumpShowcase(tester, AppTheme.light(brand));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/showcase_${brand.name}_light.png'),
        );
      });

      testWidgets('${brand.name} dark', (tester) async {
        await pumpShowcase(tester, AppTheme.dark(brand));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/showcase_${brand.name}_dark.png'),
        );
      });
    }
  });
}
