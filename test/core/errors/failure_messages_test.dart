import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/src/core/errors/failure_messages.dart';
import 'package:flutter_template/src/features/auth/auth_repository.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// A repository has no `BuildContext`, so its exceptions carry a *code* and an
/// English fallback. The UI maps the code — these tests are what make that
/// mapping trustworthy.
void main() {
  Future<AppLocalizations> l10nFor(
    WidgetTester tester, [
    Locale locale = const Locale('en'),
  ]) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return l10n;
  }

  group('auth codes', () {
    testWidgets('every code the repository maps has localised copy', (
      tester,
    ) async {
      final l10n = await l10nFor(tester);

      // Kept in step with AuthFailure._messages by hand; a code that gains
      // friendly English copy but no ARB key would silently fall through.
      const codes = [
        'invalid-email',
        'user-disabled',
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'email-already-in-use',
        'weak-password',
        'requires-recent-login',
        'too-many-requests',
        'network-request-failed',
        'operation-not-allowed',
        'no-current-user',
        'null-user',
        'unknown',
      ];

      for (final code in codes) {
        final message = localisedAuthMessage(
          l10n,
          AuthFailure(code, 'RAW FALLBACK'),
        );
        expect(
          message,
          isNot('RAW FALLBACK'),
          reason: '$code has no localised copy',
        );
        expect(message, isNotEmpty);
      }
    });

    testWidgets('wrong-password and invalid-credential read the same', (
      tester,
    ) async {
      final l10n = await l10nFor(tester);

      // The user made one mistake; newer SDKs just name it differently.
      expect(
        localisedAuthMessage(l10n, const AuthFailure('wrong-password', '')),
        localisedAuthMessage(l10n, const AuthFailure('invalid-credential', '')),
      );
    });

    testWidgets('an unmapped code falls back to the raw message', (
      tester,
    ) async {
      final l10n = await l10nFor(tester);

      // An unrecognised Firebase code usually carries a more useful sentence
      // than a generic apology.
      expect(
        localisedAuthMessage(
          l10n,
          const AuthFailure('some-new-code', 'Detail from Firebase'),
        ),
        'Detail from Firebase',
      );
    });

    testWidgets('translates into Spanish', (tester) async {
      final l10n = await l10nFor(tester, const Locale('es'));

      expect(
        localisedAuthMessage(l10n, const AuthFailure('user-not-found', '')),
        'No hay ninguna cuenta con ese correo.',
      );
    });

    testWidgets('maps a real FirebaseAuthException end to end', (tester) async {
      final l10n = await l10nFor(tester);
      final failure = AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'too-many-requests'),
      );

      expect(
        localisedAuthMessage(l10n, failure),
        'Too many attempts. Try again in a few minutes.',
      );
    });
  });

  group('storage codes', () {
    testWidgets('every mapped code has localised copy', (tester) async {
      final l10n = await l10nFor(tester);

      for (final code in [
        'unauthorized',
        'object-not-found',
        'quota-exceeded',
        'canceled',
        'unknown',
      ]) {
        expect(
          localisedStorageMessage(l10n, StorageFailure(code, 'RAW')),
          isNot('RAW'),
          reason: '$code has no localised copy',
        );
      }
    });

    testWidgets('an unmapped code falls back to the raw message', (
      tester,
    ) async {
      final l10n = await l10nFor(tester);

      expect(
        localisedStorageMessage(
          l10n,
          const StorageFailure('retry-limit-exceeded', 'Detail'),
        ),
        'Detail',
      );
    });

    testWidgets('translates into Spanish', (tester) async {
      final l10n = await l10nFor(tester, const Locale('es'));

      expect(
        localisedStorageMessage(
          l10n,
          const StorageFailure('object-not-found', ''),
        ),
        'Ese archivo ya no existe.',
      );
    });

    testWidgets('maps a real FirebaseException end to end', (tester) async {
      final l10n = await l10nFor(tester);
      final failure = StorageFailure.fromFirebase(
        FirebaseException(plugin: 'firebase_storage', code: 'unauthorized'),
      );

      expect(
        localisedStorageMessage(l10n, failure),
        'You do not have permission to do that.',
      );
    });
  });
}
