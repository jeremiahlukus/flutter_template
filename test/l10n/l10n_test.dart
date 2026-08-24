import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/l10n/l10n_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ARB files', () {
    Map<String, dynamic> arb(String locale) =>
        jsonDecode(
              File('lib/src/l10n/arb/app_$locale.arb').readAsStringSync(),
            )
            as Map<String, dynamic>;

    Set<String> messageKeys(Map<String, dynamic> data) =>
        data.keys.where((k) => !k.startsWith('@')).toSet();

    test('copy outside the notes feature names no feature', () {
      // The notes feature is a worked example a fork deletes. Onboarding, the
      // auth subtitles and the setup screen are the first copy a user reads and
      // are kept by every fork, so a stray "note" or "writing" there means the
      // fork ships marketing for a feature it removed.
      //
      // Scoped to these prefixes deliberately: keys like `untitledNote` *should*
      // say note, and go when the feature does.
      const genericPrefixes = [
        'onboarding',
        'signIn',
        'signUp',
        'signOut',
        'setup',
        'analytics',
      ];
      // Stems, so "notes"/"writing" are caught along with "note"/"write".
      const featureWords = ['note', 'writ', 'nota', 'escrib'];

      for (final locale in AppLocales.supported) {
        final data = arb(locale.languageCode);
        for (final key in messageKeys(data)) {
          if (!genericPrefixes.any(key.startsWith)) continue;
          final value = (data[key] as String).toLowerCase();
          for (final word in featureWords) {
            expect(
              value.contains(word),
              isFalse,
              reason:
                  '$key in app_${locale.languageCode}.arb says "$word": '
                  'copy a fork keeps must not name a feature it may delete',
            );
          }
        }
      }
    });

    test('every supported locale has an ARB file', () {
      for (final locale in AppLocales.supported) {
        expect(
          File('lib/src/l10n/arb/app_${locale.languageCode}.arb').existsSync(),
          isTrue,
          reason: 'missing ARB for ${locale.languageCode}',
        );
      }
    });

    test('no translation is missing', () {
      // An untranslated key silently falls back to English at runtime, which is
      // the kind of thing that ships unnoticed.
      final english = messageKeys(arb('en'));

      for (final locale in AppLocales.supported) {
        final other = messageKeys(arb(locale.languageCode));
        expect(
          english.difference(other),
          isEmpty,
          reason: '${locale.languageCode} is missing keys',
        );
      }
    });

    test('no locale carries keys English does not', () {
      final english = messageKeys(arb('en'));

      for (final locale in AppLocales.supported) {
        expect(
          messageKeys(arb(locale.languageCode)).difference(english),
          isEmpty,
          reason: '${locale.languageCode} has stale keys',
        );
      }
    });

    test('no message is left empty', () {
      for (final locale in AppLocales.supported) {
        final data = arb(locale.languageCode);
        for (final key in messageKeys(data)) {
          expect(
            (data[key] as String).trim(),
            isNotEmpty,
            reason: '$key is blank in ${locale.languageCode}',
          );
        }
      }
    });

    test('every declared placeholder appears in every translation', () {
      // Driven off the `@key.placeholders` metadata rather than a regex over the
      // string: ICU plural branches contain their own braces, so a naive scan
      // mistakes translated words for placeholder names.
      final english = arb('en');

      final declared = <String, Set<String>>{};
      for (final key in messageKeys(english)) {
        final meta = english['@$key'];
        if (meta is! Map<String, dynamic>) continue;
        final placeholders = meta['placeholders'];
        if (placeholders is Map<String, dynamic>) {
          declared[key] = placeholders.keys.toSet();
        }
      }

      expect(
        declared,
        isNotEmpty,
        reason: 'no placeholders found — has the metadata moved?',
      );

      for (final locale in AppLocales.supported) {
        final data = arb(locale.languageCode);
        declared.forEach((key, names) {
          for (final name in names) {
            // A dropped placeholder throws at runtime, not at build time.
            expect(
              data[key] as String,
              contains('{$name'),
              reason: '$key is missing {$name} in ${locale.languageCode}',
            );
          }
        });
      }
    });

    test('gen-l10n reported nothing untranslated', () {
      final file = File('lib/src/l10n/untranslated.json');
      if (!file.existsSync()) return;

      final content = file.readAsStringSync().trim();
      expect(content, anyOf('{}', isEmpty));
    });
  });

  group('AppLocales', () {
    test('ships more than one locale, so the setup is actually exercised', () {
      expect(AppLocales.supported.length, greaterThan(1));
    });

    test('English is supported', () {
      expect(
        AppLocales.supported.map((l) => l.languageCode),
        contains('en'),
      );
    });

    test('every supported locale has a display name', () {
      for (final locale in AppLocales.supported) {
        expect(
          AppLocales.names,
          contains(locale.languageCode),
          reason: 'no display name for ${locale.languageCode}',
        );
      }
    });

    test('nameOf falls back to the language code', () {
      expect(AppLocales.nameOf(const Locale('en')), 'English');
      expect(AppLocales.nameOf(const Locale('zz')), 'zz');
    });
  });

  group('LocaleController.decode', () {
    test('round-trips every supported locale', () {
      for (final locale in AppLocales.supported) {
        expect(
          LocaleController.decode(LocaleController.encode(locale)),
          locale,
        );
      }
    });

    test('null means follow the system', () {
      expect(LocaleController.decode(null), isNull);
      expect(LocaleController.encode(null), isNull);
    });

    test('an empty string means follow the system', () {
      expect(LocaleController.decode(''), isNull);
    });

    test('an unsupported code falls back to the system', () {
      // Better to follow the platform than to show a locale we cannot render.
      expect(LocaleController.decode('kl'), isNull);
    });
  });

  group('LocaleController', () {
    test('defaults to null with an empty database', () async {
      final harness = TestHarness.create();

      expect(
        await harness.container.read(localeControllerProvider.future),
        isNull,
      );
    });

    test('reads a stored locale', () async {
      final harness = TestHarness.create();
      await harness.database.writeSetting(SettingKeys.locale, 'es');

      expect(
        await harness.container.read(localeControllerProvider.future),
        const Locale('es'),
      );
    });

    test('set persists the choice', () async {
      final harness = TestHarness.create();
      await harness.container.read(localeControllerProvider.future);

      await harness
          .read(localeControllerProvider.notifier)
          .set(const Locale('es'));

      expect(await harness.database.readSetting(SettingKeys.locale), 'es');
      expect(harness.read(localeProvider), const Locale('es'));
    });

    test('setting null removes the stored value', () async {
      final harness = TestHarness.create();
      await harness.container.read(localeControllerProvider.future);
      await harness
          .read(localeControllerProvider.notifier)
          .set(const Locale('es'));

      await harness.read(localeControllerProvider.notifier).set(null);

      expect(await harness.database.readSetting(SettingKeys.locale), isNull);
      expect(harness.read(localeProvider), isNull);
    });
  });

  group('rendering', () {
    testWidgets('defaults to English', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.text('Notes'), findsOne);
    });

    testWidgets('renders Spanish when that locale is stored', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(SettingKeys.locale, 'es');
      await harness.pumpApp(tester);

      expect(find.text('Notas'), findsOne);
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('a locale change re-renders without a restart', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);
      expect(find.text('Notes'), findsOne);

      await harness
          .read(localeControllerProvider.notifier)
          .set(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Notas'), findsOne);
    });

    testWidgets('the empty state is localised too', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.database.writeSetting(SettingKeys.locale, 'es');
      await harness.pumpApp(tester);

      expect(find.text('Aún no hay notas'), findsOne);
    });
  });
}
