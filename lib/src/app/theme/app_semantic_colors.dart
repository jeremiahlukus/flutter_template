import 'package:flutter/material.dart';

/// Status colours that Material's [ColorScheme] does not provide.
///
/// `ColorScheme` gives you `error` and nothing else — but almost every app needs
/// success, warning, and info too, and hard-coding `Colors.green` breaks in dark
/// mode. A [ThemeExtension] keeps them theme-aware and reachable the same way as
/// any other themed colour:
///
/// ```dart
/// final colors = AppSemanticColors.of(context);
/// Container(color: colors.successContainer);
/// ```
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Light-mode values, tuned to sit alongside a Material 3 light scheme.
  factory AppSemanticColors.light() => const AppSemanticColors(
    success: Color(0xFF186B3A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFA6F4C0),
    onSuccessContainer: Color(0xFF00210C),
    warning: Color(0xFF8A5300),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFDDB3),
    onWarningContainer: Color(0xFF2B1700),
    info: Color(0xFF00658E),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFC5E7FF),
    onInfoContainer: Color(0xFF001E2C),
  );

  /// Dark-mode values. Roles are inverted, not merely darkened — a container in
  /// dark mode is the dim surface and the accent is the bright one.
  factory AppSemanticColors.dark() => const AppSemanticColors(
    success: Color(0xFF8BD7A5),
    onSuccess: Color(0xFF003919),
    successContainer: Color(0xFF005227),
    onSuccessContainer: Color(0xFFA6F4C0),
    warning: Color(0xFFFFB95C),
    onWarning: Color(0xFF4A2800),
    warningContainer: Color(0xFF693C00),
    onWarningContainer: Color(0xFFFFDDB3),
    info: Color(0xFF84CFFF),
    onInfo: Color(0xFF00344A),
    infoContainer: Color(0xFF004C6B),
    onInfoContainer: Color(0xFFC5E7FF),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Reads the extension from [context].
  ///
  /// Falls back to the light palette rather than throwing: a missing extension
  /// should degrade to readable colours, not crash a screen.
  //
  // `of(context)` is the Flutter convention for a lookup and reads far better
  // than a constructor at the call site.
  // ignore: prefer_constructors_over_static_methods
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ??
      AppSemanticColors.light();

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) => AppSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
  );

  /// Enables smooth colour animation when the theme changes.
  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
