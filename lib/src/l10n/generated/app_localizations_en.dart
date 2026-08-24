// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Template';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle =>
      'Welcome back. Sign in to pick up where you left off.';

  @override
  String get signUpSubtitle => 'Create an account to sync across your devices.';

  @override
  String get termsFooter => 'By continuing you agree to the Terms of Service.';

  @override
  String get notesTitle => 'Notes';

  @override
  String get newNote => 'New note';

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyBody => 'Tap \"New note\" to write your first one.';

  @override
  String get notesLoadErrorTitle => 'Could not load notes';

  @override
  String get untitledNote => 'Untitled note';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending',
      one: '1 pending',
    );
    return '$_temp0';
  }

  @override
  String get syncNowTooltip => 'Sync now';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String syncSuccess(int up, int down) {
    return 'Synced — $up up, $down down.';
  }

  @override
  String syncPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced, but $count notes could not upload.',
      one: 'Synced, but 1 note could not upload.',
    );
    return '$_temp0';
  }

  @override
  String get syncFailed => 'Sync failed. Check your connection.';

  @override
  String get editNote => 'Edit note';

  @override
  String get noteTitleLabel => 'Title';

  @override
  String get noteTitleHint => 'Give it a name';

  @override
  String get noteBodyLabel => 'Note';

  @override
  String get saveNote => 'Save note';

  @override
  String get savingNote => 'Saving…';

  @override
  String noteTitleTooLong(int max) {
    return 'Title is too long — $max characters maximum.';
  }

  @override
  String noteBodyTooLong(int max) {
    return 'Note is too long — $max characters maximum.';
  }

  @override
  String get nothingToSave => 'Nothing to save — add a title or some text.';

  @override
  String get saveFailedQueued =>
      'Could not save. Your note is kept locally and will retry.';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteBody => 'This cannot be undone.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signedOut => 'Signed out.';

  @override
  String get guest => 'Guest';

  @override
  String get emailNotVerified => 'Email not verified';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get saveName => 'Save name';

  @override
  String get nameUpdated => 'Name updated.';

  @override
  String get nameUpdateFailed => 'Could not update your name.';

  @override
  String get enterNameFirst => 'Enter a name first.';

  @override
  String get uploadAvatar => 'Upload avatar';

  @override
  String get avatarUploaded => 'Avatar uploaded.';

  @override
  String get avatarUploadedProfileFailed =>
      'Uploaded, but the profile did not update.';

  @override
  String get avatarChooseSource => 'Change avatar';

  @override
  String get avatarFromCamera => 'Take a photo';

  @override
  String get avatarFromGallery => 'Choose from library';

  @override
  String get avatarPickFailed => 'Could not read that image.';

  @override
  String get avatarRemove => 'Remove avatar';

  @override
  String get avatarRemoved => 'Avatar removed.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody => 'Your data stays synced to your account.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently removes your account and cannot be undone.';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Sign in again and retry.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get pushTitle => 'Push notifications';

  @override
  String get pushSubtitle =>
      'Get notified when something needs your attention.';

  @override
  String get pushBlocked => 'Blocked in system settings.';

  @override
  String get pushOpenSettings => 'Open settings';

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get sectionSync => 'Sync';

  @override
  String get sectionAbout => 'About';

  @override
  String get themeSystem => 'Match system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get languageSystem => 'Match system';

  @override
  String get analyticsTitle => 'Share usage analytics';

  @override
  String get analyticsSubtitle =>
      'Helps improve the app. Your content is never sent.';

  @override
  String get waitingToUpload => 'Waiting to upload';

  @override
  String get appVersion => 'Version';

  @override
  String get environmentLabel => 'Environment';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Update to keep using the app.';

  @override
  String get updateOptionalTitle => 'Update available';

  @override
  String get updateOptionalBody => 'A newer version is available.';

  @override
  String get updateAction => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get pageNotFoundBody => 'That page does not exist.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get offlineBanner => 'Offline — changes are saved on this device';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingDone => 'Get started';

  @override
  String get onboardingTitle1 => 'On all your devices';

  @override
  String get onboardingBody1 =>
      'Use any device. Everything syncs to your account automatically.';

  @override
  String get onboardingTitle2 => 'Works offline';

  @override
  String get onboardingBody2 =>
      'Keep working without a connection. Changes upload as soon as you are back.';

  @override
  String get onboardingTitle3 => 'Yours alone';

  @override
  String get onboardingBody3 =>
      'Your data lives under your account and is readable only by you.';

  @override
  String get authInvalidEmail => 'That email address is not valid.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authUserNotFound => 'No account found for that email.';

  @override
  String get authWrongPassword => 'Incorrect email or password.';

  @override
  String get authEmailInUse => 'An account already exists for that email.';

  @override
  String get authWeakPassword =>
      'Choose a password with at least 6 characters.';

  @override
  String get authRequiresRecentLogin =>
      'Please sign in again to complete this change.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get authNetworkFailed => 'Network unavailable. Check your connection.';

  @override
  String get authOperationNotAllowed => 'That sign-in method is not enabled.';

  @override
  String get authNotSignedIn => 'You are not signed in.';

  @override
  String get authGeneric => 'Something went wrong. Please try again.';

  @override
  String get setupTitle => 'Firebase setup required';

  @override
  String get setupBody =>
      'This app needs Firebase to run. Auth, your data, and file storage all depend on it, so nothing works until it is configured.';

  @override
  String get setupStepsHeading => 'Run these once, from the project root:';

  @override
  String get setupRestartHint => 'Then stop and rerun the app.';

  @override
  String get setupChecklistHint =>
      'task.md → Milestone 0 has the full checklist.';

  @override
  String get setupDetails => 'Error details';

  @override
  String get setupCopied => 'Copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get storageUnauthorized => 'You do not have permission to do that.';

  @override
  String get storageNotFound => 'That file no longer exists.';

  @override
  String get storageQuotaExceeded => 'Storage quota exceeded.';

  @override
  String get storageCanceled => 'Upload canceled.';

  @override
  String get storageGeneric => 'File operation failed.';
}
