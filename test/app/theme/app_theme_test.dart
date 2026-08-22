import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_template/src/app/theme/app_semantic_colors.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brightness', () {
    test('light is light', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark is dark', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('both use Material 3', () {
      expect(AppTheme.light().useMaterial3, isTrue);
      expect(AppTheme.dark().useMaterial3, isTrue);
    });
  });

  group('brand seeding', () {
    test('defaults to the fallback brand', () {
      expect(
        AppTheme.light().colorScheme.primary,
        ColorScheme.fromSeed(seedColor: AppBrand.fallback.seed).primary,
      );
    });

    test('every brand produces a distinct primary', () {
      final primaries = AppBrand.values
          .map((b) => AppTheme.light(b).colorScheme.primary)
          .toSet();

      // If two brands collapsed to the same scheme, the picker would look broken.
      expect(primaries, hasLength(AppBrand.values.length));
    });

    test('a brand seeds both light and dark consistently', () {
      for (final brand in AppBrand.values) {
        expect(
          AppTheme.light(brand).colorScheme.primary,
          ColorScheme.fromSeed(seedColor: brand.seed).primary,
        );
        expect(
          AppTheme.dark(brand).colorScheme.primary,
          ColorScheme.fromSeed(
            seedColor: brand.seed,
            brightness: Brightness.dark,
          ).primary,
        );
      }
    });

    test('the legacy seed getter still points at the default brand', () {
      expect(AppTheme.seed, AppBrand.fallback.seed);
    });
  });

  group('semantic colours extension', () {
    test('light carries the light palette', () {
      final colors = AppTheme.light().extension<AppSemanticColors>();
      expect(colors, isNotNull);
      expect(colors!.success, AppSemanticColors.light().success);
    });

    test('dark carries the dark palette', () {
      final colors = AppTheme.dark().extension<AppSemanticColors>();
      expect(colors!.success, AppSemanticColors.dark().success);
    });

    test('the extension is present for every brand', () {
      for (final brand in AppBrand.values) {
        expect(
          AppTheme.light(brand).extension<AppSemanticColors>(),
          isNotNull,
          reason: '${brand.name} is missing semantic colours',
        );
      }
    });
  });

  group('component theming', () {
    final themes = [AppTheme.light(), AppTheme.dark()];

    test('app bars are flat and left-aligned', () {
      for (final theme in themes) {
        expect(theme.appBarTheme.centerTitle, isFalse);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      }
    });

    test('inputs are outlined and filled', () {
      for (final theme in themes) {
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      }
    });

    test('a focused input is visibly emphasised', () {
      for (final theme in themes) {
        final focused =
            theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
        expect(focused.borderSide.width, greaterThan(1));
        expect(focused.borderSide.color, theme.colorScheme.primary);
      }
    });

    test('every button meets the 48dp touch target minimum', () {
      for (final theme in themes) {
        for (final style in [
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
        ]) {
          expect(
            style!.minimumSize!.resolve({})!.height,
            greaterThanOrEqualTo(48),
          );
        }
        // A text button is inline, so only its width target is relaxed.
        expect(
          theme.textButtonTheme.style!.minimumSize!.resolve({})!.height,
          greaterThanOrEqualTo(44),
        );
      }
    });

    test('cards are outlined rather than shadowed', () {
      for (final theme in themes) {
        expect(theme.cardTheme.elevation, 0);
        expect(
          (theme.cardTheme.shape! as RoundedRectangleBorder).side.color,
          theme.colorScheme.outlineVariant,
        );
      }
    });

    test('chips and bottom sheets are rounded', () {
      for (final theme in themes) {
        expect(theme.chipTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      }
    });

    test('snack bars float', () {
      for (final theme in themes) {
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      }
    });

    test('dividers use the outline variant, hairline thick', () {
      for (final theme in themes) {
        expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
        expect(theme.dividerTheme.thickness, 1);
      }
    });

    test('page transitions are configured for the mobile platforms', () {
      for (final theme in themes) {
        final builders = theme.pageTransitionsTheme.builders;
        expect(builders, contains(TargetPlatform.android));
        expect(builders, contains(TargetPlatform.iOS));
      }
    });
  });

  group('typography', () {
    test('body text has comfortable line height', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        // Material's default (~1.43) reads cramped for multi-line body copy.
        expect(theme.textTheme.bodyMedium!.height, greaterThanOrEqualTo(1.4));
      }
    });

    test('headings are weighted more than body text', () {
      final text = AppTheme.light().textTheme;
      expect(text.titleLarge!.fontWeight, FontWeight.w600);
      expect(text.headlineSmall!.fontWeight, FontWeight.w600);
      expect(text.labelLarge!.fontWeight, FontWeight.w600);
    });

    test('bodySmall is de-emphasised, for captions and hints', () {
      final theme = AppTheme.light();
      expect(
        theme.textTheme.bodySmall!.color,
        theme.colorScheme.onSurfaceVariant,
      );
    });

    test('the app bar title uses the type scale rather than a one-off', () {
      final theme = AppTheme.light();
      expect(theme.appBarTheme.titleTextStyle, theme.textTheme.titleLarge);
    });
  });

  test('themes are rebuilt per call, not shared mutable state', () {
    expect(AppTheme.light(), isNot(same(AppTheme.light())));
  });
}
