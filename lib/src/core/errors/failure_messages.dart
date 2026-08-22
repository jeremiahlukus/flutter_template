import 'package:flutter_template/src/features/auth/auth_repository.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';

/// Maps a failure code to localised copy.
///
/// The `message` on [AuthFailure] and [StorageFailure] is an English fallback
/// for logs — a repository has no `BuildContext`, so it cannot localise itself.
/// The UI maps the *code* instead, which is why those codes are part of the
/// exceptions' contracts rather than an implementation detail.
///
/// An unmapped code falls back to the exception's own message rather than a
/// generic apology: an unrecognised Firebase code usually carries a more useful
/// sentence than "something went wrong".
String localisedAuthMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure.code) {
      'invalid-email' => l10n.authInvalidEmail,
      'user-disabled' => l10n.authUserDisabled,
      'user-not-found' => l10n.authUserNotFound,
      // One sentence for both: newer SDKs return `invalid-credential` where
      // older ones returned `wrong-password`, and the user made one mistake.
      'wrong-password' || 'invalid-credential' => l10n.authWrongPassword,
      'email-already-in-use' => l10n.authEmailInUse,
      'weak-password' => l10n.authWeakPassword,
      'requires-recent-login' => l10n.authRequiresRecentLogin,
      'too-many-requests' => l10n.authTooManyRequests,
      'network-request-failed' => l10n.authNetworkFailed,
      'operation-not-allowed' => l10n.authOperationNotAllowed,
      'no-current-user' || 'null-user' => l10n.authNotSignedIn,
      'unknown' => l10n.authGeneric,
      _ => failure.message,
    };

String localisedStorageMessage(
  AppLocalizations l10n,
  StorageFailure failure,
) => switch (failure.code) {
  'unauthorized' => l10n.storageUnauthorized,
  'object-not-found' => l10n.storageNotFound,
  'quota-exceeded' => l10n.storageQuotaExceeded,
  'canceled' => l10n.storageCanceled,
  'unknown' => l10n.storageGeneric,
  _ => failure.message,
};
