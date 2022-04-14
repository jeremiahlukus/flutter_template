// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/core/presentation/app_widget.dart';
import 'package:flutter_template/splash/presentation/splash_page.dart';

Future<void> pumpAndSettle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    // because pumpAndSettle doesn't work with riverpod
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> main() async {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(ProviderScope(child: AppWidget()));
      await pumpAndSettle(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(SplashPage), findsOneWidget);
    });
  });
}
