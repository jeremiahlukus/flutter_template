import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/app_semantic_colors.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Relative luminance contrast ratio, per WCAG 2.1.
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('palettes', () {
    test('light and dark differ on every role', () {
      final light = AppSemanticColors.light();
      final dark = AppSemanticColors.dark();

      expect(light.success, isNot(dark.success));
      expect(light.warning, isNot(dark.warning));
      expect(light.info, isNot(dark.info));
      expect(light.successContainer, isNot(dark.successContainer));
    });

    test('foreground colours are legible on their backgrounds', () {
      // 4.5:1 is the WCAG AA minimum for body text. A status colour nobody can
      // read is worse than no status colour.
      for (final colors in [
        AppSemanticColors.light(),
        AppSemanticColors.dark(),
      ]) {
        final pairs = <String, (Color, Color)>{
          'onSuccess': (colors.onSuccess, colors.success),
          'onWarning': (colors.onWarning, colors.warning),
          'onInfo': (colors.onInfo, colors.info),
          'onSuccessContainer': (
            colors.onSuccessContainer,
            colors.successContainer,
          ),
          'onWarningContainer': (
            colors.onWarningContainer,
            colors.warningContainer,
          ),
          'onInfoContainer': (colors.onInfoContainer, colors.infoContainer),
        };

        for (final entry in pairs.entries) {
          expect(
            contrast(entry.value.$1, entry.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} fails AA contrast',
          );
        }
      }
    });
  });

  group('copyWith', () {
    test('replaces only what is passed', () {
      final base = AppSemanticColors.light();
      final updated = base.copyWith(success: const Color(0xFF000000));

      expect(updated.success, const Color(0xFF000000));
      expect(updated.warning, base.warning);
      expect(updated.infoContainer, base.infoContainer);
    });

    test('is identity when given nothing', () {
      final base = AppSemanticColors.light();
      final copy = base.copyWith();

      expect(copy.success, base.success);
      expect(copy.onSuccess, base.onSuccess);
      expect(copy.warning, base.warning);
      expect(copy.onWarning, base.onWarning);
      expect(copy.info, base.info);
      expect(copy.onInfo, base.onInfo);
    });

    test('can replace every role', () {
      const black = Color(0xFF000000);
      final updated = AppSemanticColors.light().copyWith(
        success: black,
        onSuccess: black,
        successContainer: black,
        onSuccessContainer: black,
        warning: black,
        onWarning: black,
        warningContainer: black,
        onWarningContainer: black,
        info: black,
        onInfo: black,
        infoContainer: black,
        onInfoContainer: black,
      );

      expect(
        [
          updated.success,
          updated.onSuccess,
          updated.successContainer,
          updated.onSuccessContainer,
          updated.warning,
          updated.onWarning,
          updated.warningContainer,
          updated.onWarningContainer,
          updated.info,
          updated.onInfo,
          updated.infoContainer,
          updated.onInfoContainer,
        ],
        everyElement(black),
      );
    });
  });

  group('lerp', () {
    test('at t=0 returns the starting values', () {
      final light = AppSemanticColors.light();
      final result = light.lerp(AppSemanticColors.dark(), 0);

      expect(result.success, light.success);
    });

    test('at t=1 returns the ending values', () {
      final dark = AppSemanticColors.dark();
      final result = AppSemanticColors.light().lerp(dark, 1);

      expect(result.success, dark.success);
    });

    test('at t=0.5 lands between the two', () {
      final light = AppSemanticColors.light();
      final dark = AppSemanticColors.dark();
      final mid = light.lerp(dark, 0.5);

      expect(mid.success, isNot(light.success));
      expect(mid.success, isNot(dark.success));
    });

    test('a null target is a no-op, so an animation cannot crash', () {
      final light = AppSemanticColors.light();
      expect(light.lerp(null, 0.5).success, light.success);
    });

    test('interpolates every role', () {
      final mid = AppSemanticColors.light().lerp(AppSemanticColors.dark(), 0.5);
      final light = AppSemanticColors.light();

      expect(mid.onSuccessContainer, isNot(light.onSuccessContainer));
      expect(mid.onWarningContainer, isNot(light.onWarningContainer));
      expect(mid.onInfoContainer, isNot(light.onInfoContainer));
      expect(mid.onInfo, isNot(light.onInfo));
    });
  });

  group('of(context)', () {
    testWidgets('reads the extension from the light theme', (tester) async {
      late AppSemanticColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              colors = AppSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors.success, AppSemanticColors.light().success);
    });

    testWidgets('reads the extension from the dark theme', (tester) async {
      late AppSemanticColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              colors = AppSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors.success, AppSemanticColors.dark().success);
    });

    testWidgets('falls back to light when the extension is absent', (
      tester,
    ) async {
      late AppSemanticColors colors;
      await tester.pumpWidget(
        MaterialApp(
          // A bare ThemeData carries no AppSemanticColors.
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              colors = AppSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Degrades to readable colours rather than throwing.
      expect(colors.success, AppSemanticColors.light().success);
    });
  });
}
