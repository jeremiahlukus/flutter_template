import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/widgets/app_states.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );

  group('AppEmptyState', () {
    testWidgets('shows the icon and title', (tester) async {
      await pump(
        tester,
        const AppEmptyState(icon: Icons.inbox, title: 'Nothing here'),
      );

      expect(find.byIcon(Icons.inbox), findsOne);
      expect(find.text('Nothing here'), findsOne);
    });

    testWidgets('omits the message when there is none', (tester) async {
      await pump(
        tester,
        const AppEmptyState(icon: Icons.inbox, title: 'Title'),
      );

      expect(find.byType(Text), findsOne);
    });

    testWidgets('shows the message when given', (tester) async {
      await pump(
        tester,
        const AppEmptyState(
          icon: Icons.inbox,
          title: 'Title',
          message: 'Body copy',
        ),
      );

      expect(find.text('Body copy'), findsOne);
    });

    testWidgets('shows an action when given', (tester) async {
      var tapped = false;
      await pump(
        tester,
        AppEmptyState(
          icon: Icons.inbox,
          title: 'Title',
          action: FilledButton(
            onPressed: () => tapped = true,
            child: const Text('Do it'),
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      expect(tapped, isTrue);
    });
  });

  group('AppErrorState', () {
    testWidgets('shows the title and the error text', (tester) async {
      await pump(
        tester,
        AppErrorState(title: 'Broke', error: StateError('the reason')),
      );

      expect(find.text('Broke'), findsOne);
      expect(find.textContaining('the reason'), findsOne);
    });

    testWidgets('omits retry when no callback is given', (tester) async {
      await pump(tester, const AppErrorState(title: 'Broke'));

      expect(find.byKey(const ValueKey('error_retry_button')), findsNothing);
    });

    testWidgets('offers retry when a callback is given', (tester) async {
      var retried = false;
      await pump(
        tester,
        AppErrorState(title: 'Broke', onRetry: () => retried = true),
      );

      await tester.tap(find.byKey(const ValueKey('error_retry_button')));
      expect(retried, isTrue);
    });

    testWidgets('uses a custom retry label', (tester) async {
      await pump(
        tester,
        AppErrorState(
          title: 'Broke',
          onRetry: () {},
          retryLabel: 'Try again',
        ),
      );

      expect(find.text('Try again'), findsOne);
    });

    testWidgets('defaults the retry label', (tester) async {
      await pump(tester, AppErrorState(title: 'Broke', onRetry: () {}));

      expect(find.text('Retry'), findsOne);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('shows a spinner', (tester) async {
      await pump(tester, const AppLoadingIndicator());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOne);
    });

    testWidgets('shows a label when given', (tester) async {
      await pump(tester, const AppLoadingIndicator(label: 'Syncing…'));
      await tester.pump();

      expect(find.text('Syncing…'), findsOne);
    });
  });

  group('AsyncValueView', () {
    Widget view(
      AsyncValue<List<int>> value, {
      bool Function(List<int>)? isEmpty,
      Widget Function()? onEmpty,
      VoidCallback? onRetry,
      Key? errorKey,
    }) => AsyncValueView<List<int>>(
      value: value,
      errorKey: errorKey,
      onRetry: onRetry,
      isEmpty: isEmpty,
      onEmpty: onEmpty,
      data: (v) => Text('${v.length} items'),
    );

    testWidgets('renders data', (tester) async {
      await pump(tester, view(const AsyncValue.data([1, 2, 3])));

      expect(find.text('3 items'), findsOne);
    });

    testWidgets('renders a spinner while loading', (tester) async {
      await pump(tester, view(const AsyncValue.loading()));
      await tester.pump();

      expect(find.byKey(const ValueKey('async_loading')), findsOne);
    });

    testWidgets('renders the error state on failure', (tester) async {
      await pump(
        tester,
        view(AsyncValue.error(StateError('nope'), StackTrace.empty)),
      );

      expect(find.textContaining('nope'), findsOne);
    });

    testWidgets('applies errorKey so drivers can target the state', (
      tester,
    ) async {
      await pump(
        tester,
        view(
          AsyncValue.error(StateError('nope'), StackTrace.empty),
          errorKey: const ValueKey('my_error'),
        ),
      );

      expect(find.byKey(const ValueKey('my_error')), findsOne);
    });

    testWidgets('wires retry through to the error state', (tester) async {
      var retried = false;
      await pump(
        tester,
        view(
          AsyncValue.error(StateError('nope'), StackTrace.empty),
          onRetry: () => retried = true,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('error_retry_button')));
      expect(retried, isTrue);
    });

    testWidgets('renders the empty state for loaded-but-empty data', (
      tester,
    ) async {
      await pump(
        tester,
        view(
          const AsyncValue.data([]),
          isEmpty: (v) => v.isEmpty,
          onEmpty: () => const Text('Nothing yet'),
        ),
      );

      // "Loaded but empty" is a distinct state from "loading"; conflating them
      // is how an empty screen ends up spinning forever.
      expect(find.text('Nothing yet'), findsOne);
      expect(find.byKey(const ValueKey('async_loading')), findsNothing);
    });

    testWidgets('renders data when isEmpty says it is not empty', (
      tester,
    ) async {
      await pump(
        tester,
        view(
          const AsyncValue.data([1]),
          isEmpty: (v) => v.isEmpty,
          onEmpty: () => const Text('Nothing yet'),
        ),
      );

      expect(find.text('1 items'), findsOne);
    });

    testWidgets('falls through to data when onEmpty is not supplied', (
      tester,
    ) async {
      await pump(
        tester,
        view(const AsyncValue.data([]), isEmpty: (v) => v.isEmpty),
      );

      expect(find.text('0 items'), findsOne);
    });

    testWidgets('uses a custom loading widget when given', (tester) async {
      await pump(
        tester,
        AsyncValueView<int>(
          value: const AsyncValue.loading(),
          loading: const Text('Hold on'),
          data: (v) => Text('$v'),
        ),
      );

      expect(find.text('Hold on'), findsOne);
    });
  });
}
