import 'package:flutter/material.dart';

/// Spacing scale, in logical pixels.
///
/// A fixed scale rather than ad-hoc numbers: once every gap in the app is one of
/// these seven values, layouts stay visually consistent without anyone having to
/// remember whether the last card used 12 or 14.
abstract final class AppSpacing {
  /// 4 — hairline gaps, icon-to-label.
  static const xxs = 4.0;

  /// 8 — inside a chip or dense row.
  static const xs = 8.0;

  /// 12 — between related controls.
  static const sm = 12.0;

  /// 16 — the default. Screen padding, list item padding.
  static const md = 16.0;

  /// 24 — between sections.
  static const lg = 24.0;

  /// 32 — around a hero or empty state.
  static const xl = 32.0;

  /// 48 — top-level page breathing room.
  static const xxl = 48.0;

  /// Uniform padding at [md]. The most common padding in the app.
  static const pagePadding = EdgeInsets.all(md);

  /// Horizontal-only page padding, for lists that supply their own vertical.
  static const pageHorizontal = EdgeInsets.symmetric(horizontal: md);

  /// Extra bottom room so a floating action button never covers the last row.
  static const listBottom = EdgeInsets.only(bottom: 96);
}

/// Corner radii.
abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 28.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));

  /// Fully rounded, for pills and avatars.
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Animation durations.
///
/// Named by intent rather than by number, so "make it snappier" is a one-line
/// change here instead of a hunt through the widget tree.
abstract final class AppDurations {
  /// 120ms — a control acknowledging a tap.
  static const instant = Duration(milliseconds: 120);

  /// 200ms — the default. Fades, expansions, colour changes.
  static const quick = Duration(milliseconds: 200);

  /// 320ms — page transitions.
  static const moderate = Duration(milliseconds: 320);

  /// 4s — how long a snack bar stays up.
  static const snackBar = Duration(seconds: 4);
}

/// Layout breakpoints, matching Material 3's window size classes.
///
/// Used by [AppBreakpoints.of] to pick a layout rather than by scattering
/// `MediaQuery` width checks through the widget tree.
abstract final class AppBreakpoints {
  /// Below this, assume a phone in portrait.
  static const compact = 600.0;

  /// Below this, a tablet in portrait or a phone in landscape.
  static const medium = 840.0;

  /// At or above [medium], a tablet in landscape or a desktop window.
  static WindowSize of(BuildContext context) =>
      sizeForWidth(MediaQuery.sizeOf(context).width);

  @visibleForTesting
  static WindowSize sizeForWidth(double width) {
    if (width < compact) return WindowSize.compact;
    if (width < medium) return WindowSize.medium;
    return WindowSize.expanded;
  }

  /// Content width cap on wide screens.
  ///
  /// Text lines longer than roughly this are measurably harder to read, so a
  /// desktop window gets a centred column rather than full-bleed content.
  static const maxContentWidth = 720.0;
}

enum WindowSize {
  compact,
  medium,
  expanded;

  bool get isCompact => this == WindowSize.compact;

  /// True when there is room for a side-by-side layout.
  bool get isWide => this != WindowSize.compact;
}
