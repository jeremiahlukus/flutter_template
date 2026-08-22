import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many rows a page adds.
///
/// Large enough that a normal screen fills in one page, small enough that the
/// first paint is not waiting on hundreds of rows.
const defaultPageSize = 30;

/// A growing window over an ordered collection.
///
/// This is the state behind "infinite scroll" for a *reactive* list. Rather than
/// accumulating pages in memory — which fights a stream that re-emits on every
/// write — it tracks how many rows the UI currently wants, and the query is
/// re-run bounded to that. Simpler, always consistent, and cheap on SQLite.
///
/// Note what is deliberately *absent*: any notion of the collection's total.
/// Whether more rows exist is already implied by the result — a query that
/// returns fewer rows than [size] has hit the end — so tracking a separate count
/// would mean a second query, a second stream, and two sources of truth that can
/// disagree.
@immutable
class PageWindow {
  const PageWindow({
    this.size = defaultPageSize,
    this.pageSize = defaultPageSize,
  });

  /// Rows currently requested.
  final int size;

  /// Rows added per [grown] call.
  final int pageSize;

  PageWindow grown() => PageWindow(size: size + pageSize, pageSize: pageSize);

  /// Shrinks back to a single page. Used when the underlying list is replaced —
  /// after a sign-out, say — so the window does not stay huge over new data.
  ///
  /// `size` comes from [pageSize], not the default: a window configured with a
  /// custom page size must reset to *its* page, not to 30.
  PageWindow reset() => PageWindow(size: pageSize, pageSize: pageSize);

  /// Whether a result of [loaded] rows means more may exist.
  ///
  /// A short result is the end of the collection; a full one means there is
  /// probably more. Being wrong in the "probably" direction costs one extra
  /// bounded query, which is why this is preferred over a count.
  bool hasMoreAfter(int loaded) => loaded >= size;

  @override
  bool operator ==(Object other) =>
      other is PageWindow && other.size == size && other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(size, pageSize);

  @override
  String toString() => 'PageWindow($size, +$pageSize)';
}

/// Drives a [PageWindow]. One per paged list.
class PageWindowController extends Notifier<PageWindow> {
  PageWindowController({this.pageSize = defaultPageSize});

  final int pageSize;

  @override
  PageWindow build() => PageWindow(size: pageSize, pageSize: pageSize);

  /// Requests one more page.
  ///
  /// The caller decides whether more exists — see [PageWindow.hasMoreAfter] —
  /// because only the caller has the result to judge it by.
  void loadMore() => state = state.grown();

  void reset() => state = state.reset();
}
