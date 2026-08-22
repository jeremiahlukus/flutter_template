import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Renders the app at real device widths.
///
/// The tokens are unit-tested, but a constant nobody applies is worthless — these
/// assert the *layout* actually honours `maxContentWidth` and does not overflow
/// at any size.
void main() {
  /// Sizes chosen to straddle both breakpoints.
  const sizes = <String, Size>{
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'tablet portrait': Size(768, 1024),
    'desktop': Size(1440, 900),
  };

  void useSize(WidgetTester tester, Size size) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  sizes.forEach((label, size) {
    testWidgets('the notes list renders at $label without overflowing', (
      tester,
    ) async {
      useSize(tester, size);
      final harness = TestHarness.create(user: testUser());
      await harness.database.upsertNote(testNote().toRow());
      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('First note'), findsOne);
    });

    testWidgets('settings renders at $label without overflowing', (
      tester,
    ) async {
      useSize(tester, size);
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the editor renders at $label without overflowing', (
      tester,
    ) async {
      useSize(tester, size);
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('new_note_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding renders at $label without overflowing', (
      tester,
    ) async {
      useSize(tester, size);
      final harness = TestHarness.create(onboardingCompleted: false);
      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('onboarding_pages')), findsOne);
    });
  });

  group('content width capping', () {
    testWidgets('the editor is capped on a desktop window', (tester) async {
      useSize(tester, const Size(1440, 900));
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('new_note_button')));
      await tester.pumpAndSettle();

      final field = tester.getSize(
        find.byKey(const ValueKey('note_title_field')),
      );

      // A text field spanning a desktop monitor is measurably harder to read.
      expect(field.width, lessThanOrEqualTo(AppBreakpoints.maxContentWidth));
      expect(field.width, lessThan(1440));
    });

    testWidgets('the editor is full-width on a phone', (tester) async {
      useSize(tester, const Size(390, 844));
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('new_note_button')));
      await tester.pumpAndSettle();

      final field = tester.getSize(
        find.byKey(const ValueKey('note_title_field')),
      );

      // Capping must not shrink content on a screen narrower than the cap.
      expect(field.width, greaterThan(300));
    });

    testWidgets('settings is capped on a desktop window', (tester) async {
      useSize(tester, const Size(1440, 900));
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();

      final list = tester.getSize(find.byType(ListView).first);

      expect(list.width, lessThanOrEqualTo(AppBreakpoints.maxContentWidth));
    });
  });

  group('window size classification matches the rendered width', () {
    for (final entry in sizes.entries) {
      testWidgets('${entry.key} classifies consistently', (tester) async {
        useSize(tester, entry.value);
        late WindowSize classified;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                classified = AppBreakpoints.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          classified,
          AppBreakpoints.sizeForWidth(entry.value.width),
          reason: 'MediaQuery and sizeForWidth disagree',
        );
      });
    }
  });
}
