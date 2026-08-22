import 'package:flutter/material.dart';

/// Selectable brand palettes.
///
/// Material 3 derives an entire scheme from one seed colour, so "rebrand the app"
/// is a one-value change. Shipping several presets means a new project can look
/// like itself before anyone opens a design tool — and the picker in Settings
/// doubles as a live preview of the whole design system.
enum AppBrand {
  indigo('Indigo', Color(0xFF3D5AFE)),
  teal('Teal', Color(0xFF00897B)),
  violet('Violet', Color(0xFF7C4DFF)),
  amber('Amber', Color(0xFFFF8F00)),
  crimson('Crimson', Color(0xFFD32F2F)),
  slate('Slate', Color(0xFF455A64));

  const AppBrand(this.label, this.seed);

  /// Human-readable name, shown in Settings.
  final String label;

  /// The single colour every other colour in the theme is derived from.
  final Color seed;

  /// The template's default.
  static const fallback = AppBrand.indigo;

  /// Parses a persisted value, falling back rather than throwing.
  ///
  /// A corrupt preference should not brick the app, so an unknown name silently
  /// becomes [fallback].
  static AppBrand decode(String? raw) {
    for (final brand in AppBrand.values) {
      if (brand.name == raw) return brand;
    }
    return fallback;
  }

  String encode() => name;
}
