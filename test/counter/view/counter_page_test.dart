// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:flutter_template/app/app.dart';

void main() {
  group('CounterView', () {
    testWidgets('update the UI when incrementing the state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));

      // The default value is `0`, as declared in our provider
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Increment the state and re-render
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
      await tester.pump();

      // The state have properly incremented
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('update the UI when decrementing the state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));

      // The default value is `0`, as declared in our provider
      expect(find.text('0'), findsOneWidget);
      expect(find.text('-1'), findsNothing);

      // Increment the state and re-render
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.remove));
      await tester.pump();

      // The state have properly incremented
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('the counter state is not shared between tests',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));

      // The state is `0` once again, with no tearDown/setUp needed
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });
  });
}
