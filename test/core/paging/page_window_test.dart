import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/paging/page_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageWindow', () {
    test('defaults to one page', () {
      const window = PageWindow();

      expect(window.size, defaultPageSize);
      expect(window.pageSize, defaultPageSize);
    });

    test('grown adds exactly one page', () {
      const window = PageWindow(size: 10, pageSize: 10);

      expect(window.grown().size, 20);
      expect(window.grown().grown().size, 30);
    });

    test('grown preserves the page size', () {
      expect(const PageWindow(size: 10, pageSize: 10).grown().pageSize, 10);
    });

    test('reset shrinks to the configured page, not the default', () {
      const window = PageWindow(size: 300, pageSize: 10);

      expect(window.reset().size, 10);
      expect(window.reset().pageSize, 10);
    });

    group('hasMoreAfter', () {
      test('a full page means more may exist', () {
        expect(
          const PageWindow(size: 10, pageSize: 10).hasMoreAfter(10),
          isTrue,
        );
      });

      test('a short result is the end', () {
        expect(
          const PageWindow(size: 10, pageSize: 10).hasMoreAfter(4),
          isFalse,
        );
      });

      test('an empty result is the end', () {
        expect(
          const PageWindow(size: 10, pageSize: 10).hasMoreAfter(0),
          isFalse,
        );
      });

      test('more rows than asked for still means more may exist', () {
        // Defensive: an unbounded query should not read as "the end".
        expect(
          const PageWindow(size: 10, pageSize: 10).hasMoreAfter(50),
          isTrue,
        );
      });
    });

    test('value equality and hashing', () {
      expect(
        const PageWindow(size: 10, pageSize: 10),
        const PageWindow(size: 10, pageSize: 10),
      );
      expect(
        const PageWindow(size: 10, pageSize: 10).hashCode,
        const PageWindow(size: 10, pageSize: 10).hashCode,
      );
      expect(
        const PageWindow(size: 10, pageSize: 10),
        isNot(const PageWindow(size: 20, pageSize: 10)),
      );
      expect(
        const PageWindow(size: 10, pageSize: 10),
        isNot(equals('not a window')),
      );
    });

    test('toString shows the size and step', () {
      final text = const PageWindow(size: 90, pageSize: 45).toString();

      expect(text, contains('90'));
      expect(text, contains('45'));
    });
  });

  group('PageWindowController', () {
    final provider = NotifierProvider<PageWindowController, PageWindow>(
      PageWindowController.new,
    );

    ProviderContainer boot() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {}, fireImmediately: true);
      return container;
    }

    test('starts at one page', () {
      expect(boot().read(provider).size, defaultPageSize);
    });

    test('loadMore grows the window', () {
      final container = boot();

      container.read(provider.notifier).loadMore();

      expect(container.read(provider).size, defaultPageSize * 2);
    });

    test('loadMore is cumulative', () {
      final container = boot();

      container.read(provider.notifier)
        ..loadMore()
        ..loadMore();

      expect(container.read(provider).size, defaultPageSize * 3);
    });

    test('reset shrinks the window', () {
      final container = boot();
      container.read(provider.notifier).loadMore();

      container.read(provider.notifier).reset();

      expect(container.read(provider).size, defaultPageSize);
    });

    test('honours a custom page size', () {
      final custom = NotifierProvider<PageWindowController, PageWindow>(
        () => PageWindowController(pageSize: 5),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(custom, (_, _) {}, fireImmediately: true);

      expect(container.read(custom).size, 5);
      container.read(custom.notifier).loadMore();
      expect(container.read(custom).size, 10);
    });
  });
}
