import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Application name, shown in the task switcher and sign-in header
  ///
  /// In en, this message translates to:
  /// **'Flutter Template'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Sign in to sync your notes.'**
  String get signInSubtitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to sync your notes across devices.'**
  String get signUpSubtitle;

  /// No description provided for @termsFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms of Service.'**
  String get termsFooter;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New note\" to write your first one.'**
  String get notesEmptyBody;

  /// No description provided for @notesLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load notes'**
  String get notesLoadErrorTitle;

  /// Placeholder title for a note saved with a body but no title
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get untitledNote;

  /// Badge showing how many notes are waiting to upload
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending} other{{count} pending}}'**
  String pendingCount(int count);

  /// No description provided for @syncNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// Snack bar after a clean sync
  ///
  /// In en, this message translates to:
  /// **'Synced — {up} up, {down} down.'**
  String syncSuccess(int up, int down);

  /// Snack bar when some writes are still stuck. Must not read as plain success.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Synced, but 1 note could not upload.} other{Synced, but {count} notes could not upload.}}'**
  String syncPartial(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Check your connection.'**
  String get syncFailed;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @noteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleLabel;

  /// No description provided for @noteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get noteTitleHint;

  /// No description provided for @noteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteBodyLabel;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @savingNote.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingNote;

  /// No description provided for @noteTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title is too long — {max} characters maximum.'**
  String noteTitleTooLong(int max);

  /// No description provided for @noteBodyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Note is too long — {max} characters maximum.'**
  String noteBodyTooLong(int max);

  /// No description provided for @nothingToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save — add a title or some text.'**
  String get nothingToSave;

  /// No description provided for @saveFailedQueued.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your note is kept locally and will retry.'**
  String get saveFailedQueued;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteNoteBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get signedOut;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get emailNotVerified;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get saveName;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated.'**
  String get nameUpdated;

  /// No description provided for @nameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your name.'**
  String get nameUpdateFailed;

  /// No description provided for @enterNameFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a name first.'**
  String get enterNameFirst;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload avatar'**
  String get uploadAvatar;

  /// No description provided for @avatarUploaded.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded.'**
  String get avatarUploaded;

  /// No description provided for @avatarUploadedProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Uploaded, but the profile did not update.'**
  String get avatarUploadedProfileFailed;

  /// No description provided for @avatarChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get avatarChooseSource;

  /// No description provided for @avatarFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get avatarFromCamera;

  /// No description provided for @avatarFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get avatarFromGallery;

  /// No description provided for @avatarPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that image.'**
  String get avatarPickFailed;

  /// No description provided for @avatarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove avatar'**
  String get avatarRemove;

  /// No description provided for @avatarRemoved.
  ///
  /// In en, this message translates to:
  /// **'Avatar removed.'**
  String get avatarRemoved;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your notes stay synced to your account.'**
  String get signOutBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account and cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Sign in again and retry.'**
  String get deleteAccountFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// No description provided for @pushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushTitle;

  /// No description provided for @pushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when something needs your attention.'**
  String get pushSubtitle;

  /// No description provided for @pushBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked in system settings.'**
  String get pushBlocked;

  /// No description provided for @pushOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get pushOpenSettings;

  /// No description provided for @sectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get sectionPrivacy;

  /// No description provided for @sectionSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sectionSync;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColour.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get accentColour;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get languageSystem;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share usage analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps improve the app. No note content is ever sent.'**
  String get analyticsSubtitle;

  /// No description provided for @waitingToUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload'**
  String get waitingToUpload;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @environmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentLabel;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Update to keep using the app.'**
  String get updateRequiredBody;

  /// No description provided for @updateOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateOptionalTitle;

  /// No description provided for @updateOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version is available.'**
  String get updateOptionalBody;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateAction;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'That page does not exist.'**
  String get pageNotFoundBody;

  /// No description provided for @backToNotes.
  ///
  /// In en, this message translates to:
  /// **'Back to notes'**
  String get backToNotes;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes are saved on this device'**
  String get offlineBanner;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingDone;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your notes, everywhere'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Write on any device. Everything syncs to your account automatically.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Keep writing without a connection. Changes upload as soon as you are back.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Yours alone'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Notes live under your account and are readable only by you.'**
  String get onboardingBody3;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address is not valid.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for that email.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authWrongPassword;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for that email.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password with at least 6 characters.'**
  String get authWeakPassword;

  /// No description provided for @authRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to complete this change.'**
  String get authRequiresRecentLogin;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Check your connection.'**
  String get authNetworkFailed;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That sign-in method is not enabled.'**
  String get authOperationNotAllowed;

  /// No description provided for @authNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in.'**
  String get authNotSignedIn;

  /// No description provided for @authGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGeneric;

  /// Shown instead of the app when Firebase has not been configured
  ///
  /// In en, this message translates to:
  /// **'Firebase setup required'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'This app needs Firebase to run. Auth, notes, and file storage all depend on it, so nothing works until it is configured.'**
  String get setupBody;

  /// No description provided for @setupStepsHeading.
  ///
  /// In en, this message translates to:
  /// **'Run these once, from the project root:'**
  String get setupStepsHeading;

  /// No description provided for @setupRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Then stop and rerun the app.'**
  String get setupRestartHint;

  /// No description provided for @setupChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'task.md → Milestone 0 has the full checklist.'**
  String get setupChecklistHint;

  /// No description provided for @setupDetails.
  ///
  /// In en, this message translates to:
  /// **'Error details'**
  String get setupDetails;

  /// No description provided for @setupCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get setupCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @storageUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do that.'**
  String get storageUnauthorized;

  /// No description provided for @storageNotFound.
  ///
  /// In en, this message translates to:
  /// **'That file no longer exists.'**
  String get storageNotFound;

  /// No description provided for @storageQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Storage quota exceeded.'**
  String get storageQuotaExceeded;

  /// No description provided for @storageCanceled.
  ///
  /// In en, this message translates to:
  /// **'Upload canceled.'**
  String get storageCanceled;

  /// No description provided for @storageGeneric.
  ///
  /// In en, this message translates to:
  /// **'File operation failed.'**
  String get storageGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
