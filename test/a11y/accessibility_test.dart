import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/firebase_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Accessibility guarantees, asserted with Flutter's own guideline matchers.
///
/// These catch a whole class of bug that no other test in the suite does: a
/// control too small to hit reliably, an icon button with no label for a screen
/// reader, or text that overflows the moment someone turns font scaling up.
/// All three are invisible in a normal test run and obvious to an affected user.
void main() {
  /// Every screen a signed-in user can reach, and how to get there.
  final screens = <String, Future<void> Function(WidgetTester, TestHarness)>{
    'notes list': (tester, harness) async {},
    'note editor': (tester, harness) async {
      await tester.tap(find.byKey(const ValueKey('new_note_button')));
      await tester.pumpAndSettle();
    },
    'profile': (tester, harness) async {
      await tester.tap(find.byKey(const ValueKey('profile_button')));
      await tester.pumpAndSettle();
    },
    'settings': (tester, harness) async {
      await tester.tap(find.byKey(const ValueKey('settings_button')));
      await tester.pumpAndSettle();
    },
  };

  Future<TestHarness> open(
    WidgetTester tester,
    Future<void> Function(WidgetTester, TestHarness) navigate, {
    int notes = 3,
  }) async {
    final harness = TestHarness.create(user: testUser());
    for (var i = 0; i < notes; i++) {
      await harness.database.upsertNote(
        testNote(
          id: 'n$i',
          title: 'Note $i',
          updatedAt: DateTime.utc(2026).add(Duration(minutes: i)),
        ).toRow(),
      );
    }
    await harness.pumpApp(tester);
    await navigate(tester, harness);
    return harness;
  }

  group('tap targets', () {
    // 48x48 is the Material minimum, and the one people most often miss on
    // icon-only buttons.
    screens.forEach((name, navigate) {
      testWidgets('$name meets the minimum tap target size', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester, navigate);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        handle.dispose();
      });
    });
  });

  group('labels', () {
    screens.forEach((name, navigate) {
      testWidgets('$name has a label on every tappable', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester, navigate);

        // An unlabelled icon button is silence to a screen reader.
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      });
    });
  });

  group('text contrast', () {
    screens.forEach((name, navigate) {
      testWidgets('$name meets text contrast in light mode', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester, navigate);

        await expectLater(tester, meetsGuideline(textContrastGuideline));

        handle.dispose();
      });
    });

    testWidgets('the notes list meets text contrast in dark mode', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final handle = tester.ensureSemantics();

      await open(tester, (t, h) async {});

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('large text', () {
    /// The largest scale iOS and Android expose without accessibility sizes.
    const bigText = TextScaler.linear(2);

    void useLargeText(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    screens.forEach((name, navigate) {
      testWidgets('$name renders at 2x text scale without overflowing', (
        tester,
      ) async {
        useLargeText(tester);

        await open(tester, navigate);

        // An overflow throws in a test, so a clean run is the assertion.
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('the sign-in screen survives 2x text scale', (tester) async {
      useLargeText(tester);
      final harness = TestHarness.create();

      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding survives 2x text scale', (tester) async {
      useLargeText(tester);
      final harness = TestHarness.create(onboardingCompleted: false);

      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the Firebase setup screen survives 2x text scale', (
      tester,
    ) async {
      useLargeText(tester);

      // The one screen that must work when nothing else does.
      await tester.pumpWidget(const FirebaseSetupApp());
      await tester.pumpAndSettle();
      expect(bigText.scale(10), 20);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long note title does not overflow at 2x', (tester) async {
      useLargeText(tester);
      final harness = TestHarness.create(user: testUser());
      await harness.database.upsertNote(
        testNote(title: 'x' * 200, body: 'y' * 300).toRow(),
      );

      await harness.pumpApp(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('semantics tree', () {
    testWidgets('the notes list exposes its rows to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, (t, h) async {});

      // A `ListTile` merges its title and subtitle into one label, so match on
      // a pattern rather than the exact title.
      expect(
        find.bySemanticsLabel(RegExp('Note 2')),
        findsOne,
        reason: 'a row a screen reader cannot find is a row it cannot open',
      );

      handle.dispose();
    });

    testWidgets('every icon-only action carries a tooltip', (tester) async {
      await open(tester, (t, h) async {});

      // A tooltip populates the semantics `tooltip` field — *not* `label` —
      // which is what `labeledTapTargetGuideline` accepts for an icon button.
      // Asserting on it directly documents where the label actually comes from.
      expect(find.byTooltip('Sync now'), findsOne);
      expect(find.byTooltip('Settings'), findsOne);
      expect(find.byTooltip('Profile'), findsOne);
    });

    testWidgets('the editor back button is labelled', (tester) async {
      await open(tester, screens['note editor']!);

      expect(find.byTooltip('Back'), findsOne);
    });

    testWidgets('the profile back button is labelled', (tester) async {
      await open(tester, screens['profile']!);

      expect(find.byTooltip('Back'), findsOne);
    });
  });
}
