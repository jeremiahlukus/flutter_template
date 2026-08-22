import 'package:flutter/widgets.dart';
import 'package:flutter_template/src/l10n/generated/app_localizations.dart';

export 'package:flutter_template/src/l10n/generated/app_localizations.dart';

/// Shorthand for the current translations.
///
/// `context.l10n.notesTitle` rather than
/// `AppLocalizations.of(context)!.notesTitle` at ~200 call sites.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The locales this app ships translations for.
///
/// Exposed as a constant so Settings can build its picker from the same list
/// `MaterialApp` is configured with — one source of truth, so adding a locale is
/// a single ARB file plus a rebuild.
abstract final class AppLocales {
  static const supported = AppLocalizations.supportedLocales;

  /// Shown in the language picker. Each name is written in its own language,
  /// which is the convention users expect.
  static const names = <String, String>{
    'en': 'English',
    'es': 'Español',
  };

  static String nameOf(Locale locale) =>
      names[locale.languageCode] ?? locale.languageCode;
}
