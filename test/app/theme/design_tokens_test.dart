import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing', () {
    test('the scale is strictly ascending', () {
      const scale = [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];

      for (var i = 1; i < scale.length; i++) {
        expect(
          scale[i],
          greaterThan(scale[i - 1]),
          reason: 'step $i breaks the ordering',
        );
      }
    });

    test('every step is a whole number of logical pixels', () {
      // Fractional spacing lands on half-pixels at 1x and looks blurry.
      for (final value in [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ]) {
        expect(value % 1, 0, reason: '$value is not whole');
      }
    });

    test('pagePadding is uniform at the default step', () {
      expect(AppSpacing.pagePadding, const EdgeInsets.all(AppSpacing.md));
    });

    test('pageHorizontal has no vertical component', () {
      expect(AppSpacing.pageHorizontal.top, 0);
      expect(AppSpacing.pageHorizontal.left, AppSpacing.md);
    });

    test('listBottom leaves room for a floating action button', () {
      // A standard extended FAB plus its margin is about 72dp.
      expect(AppSpacing.listBottom.bottom, greaterThanOrEqualTo(72));
    });
  });

  group('AppRadius', () {
    test('the scale is strictly ascending', () {
      const scale = [
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('the convenience BorderRadius values match their scalars', () {
      expect(AppRadius.smAll.topLeft.x, AppRadius.sm);
      expect(AppRadius.mdAll.topLeft.x, AppRadius.md);
      expect(AppRadius.lgAll.topLeft.x, AppRadius.lg);
    });

    test('pill is large enough to fully round any control', () {
      expect(AppRadius.pill.topLeft.x, greaterThanOrEqualTo(999));
    });
  });

  group('AppDurations', () {
    test('are ordered from fastest to slowest', () {
      expect(AppDurations.instant, lessThan(AppDurations.quick));
      expect(AppDurations.quick, lessThan(AppDurations.moderate));
      expect(AppDurations.moderate, lessThan(AppDurations.snackBar));
    });

    test('no transition is slow enough to feel sluggish', () {
      // Beyond ~400ms a UI transition reads as lag rather than motion.
      expect(
        AppDurations.moderate,
        lessThanOrEqualTo(const Duration(milliseconds: 400)),
      );
    });

    test('a snack bar stays up long enough to read', () {
      expect(
        AppDurations.snackBar,
        greaterThanOrEqualTo(const Duration(seconds: 3)),
      );
    });
  });

  group('AppBreakpoints', () {
    test('classifies a phone as compact', () {
      expect(AppBreakpoints.sizeForWidth(390), WindowSize.compact);
    });

    test('classifies a tablet portrait as medium', () {
      expect(AppBreakpoints.sizeForWidth(700), WindowSize.medium);
    });

    test('classifies a desktop window as expanded', () {
      expect(AppBreakpoints.sizeForWidth(1400), WindowSize.expanded);
    });

    test('the compact boundary is exclusive', () {
      expect(AppBreakpoints.sizeForWidth(599), WindowSize.compact);
      expect(AppBreakpoints.sizeForWidth(600), WindowSize.medium);
    });

    test('the medium boundary is exclusive', () {
      expect(AppBreakpoints.sizeForWidth(839), WindowSize.medium);
      expect(AppBreakpoints.sizeForWidth(840), WindowSize.expanded);
    });

    test('a zero width does not throw', () {
      expect(AppBreakpoints.sizeForWidth(0), WindowSize.compact);
    });

    testWidgets('of() reads the width from MediaQuery', (tester) async {
      late WindowSize size;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(
            builder: (context) {
              size = AppBreakpoints.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(size, WindowSize.expanded);
    });

    test('maxContentWidth keeps lines readable', () {
      // Much beyond this, line length hurts reading speed.
      expect(AppBreakpoints.maxContentWidth, inInclusiveRange(600, 900));
    });
  });

  group('WindowSize', () {
    test('isCompact is true only for compact', () {
      expect(WindowSize.compact.isCompact, isTrue);
      expect(WindowSize.medium.isCompact, isFalse);
      expect(WindowSize.expanded.isCompact, isFalse);
    });

    test('isWide is the inverse of isCompact', () {
      for (final size in WindowSize.values) {
        expect(size.isWide, !size.isCompact);
      }
    });
  });
}
