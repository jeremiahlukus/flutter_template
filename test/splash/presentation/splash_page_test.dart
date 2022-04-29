// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:flutter_template/splash/presentation/splash_page.dart';

void main() {
  group('SplashPage', () {
    testWidgets('contains the FontAwesomeIcons.github icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(),
        ),
      );

      await tester.pump(Duration.zero);

      final githubIconFinder = find.byWidgetPredicate(
        (Widget widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.github,
      );

      expect(githubIconFinder, findsOneWidget);
    });

    testWidgets('contains the LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(),
        ),
      );

      await tester.pump(Duration.zero);

      final linearProgressIndicatorFinder = find.byType(
        LinearProgressIndicator,
      );

      expect(linearProgressIndicatorFinder, findsOneWidget);
    });
  });
}
