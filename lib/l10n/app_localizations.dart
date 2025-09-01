import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ko'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Routine - 24-Hour Clock Selector'**
  String get appTitle;

  /// The title shown on the home page
  ///
  /// In en, this message translates to:
  /// **'24-Hour Clock Selector'**
  String get homeTitle;

  /// Settings button text
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title for time slots section
  ///
  /// In en, this message translates to:
  /// **'Your Time Slots'**
  String get yourTimeSlots;

  /// Message when there are no time slots
  ///
  /// In en, this message translates to:
  /// **'No time slots yet. Tap + to create one or drag on the circle!'**
  String get noTimeSlotsYet;

  /// Title for routine slots dialog
  ///
  /// In en, this message translates to:
  /// **'Routine Slots'**
  String get routineSlots;

  /// Prompt to sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your routines'**
  String get signInToSync;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Facebook sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password input field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Email sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signInWithEmail;

  /// Email sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up with Email'**
  String get signUpWithEmail;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Upgrade to pro button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToProButton;

  /// Pro member badge text
  ///
  /// In en, this message translates to:
  /// **'PRO MEMBER'**
  String get proMember;

  /// Free user badge text
  ///
  /// In en, this message translates to:
  /// **'FREE USER'**
  String get freeUser;

  /// Add new routine slot button text
  ///
  /// In en, this message translates to:
  /// **'Add New Routine Slot'**
  String get addNewRoutineSlot;

  /// Status text for active routine slot
  ///
  /// In en, this message translates to:
  /// **'Currently Active'**
  String get currentlyActive;

  /// Status text for inactive routine slot
  ///
  /// In en, this message translates to:
  /// **'Tap to activate'**
  String get tapToActivate;

  /// Rename menu item
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Duplicate menu item
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Delete menu item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Rename routine dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename Routine'**
  String get renameRoutine;

  /// Routine name input field label
  ///
  /// In en, this message translates to:
  /// **'Routine Name'**
  String get routineName;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete routine dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get deleteRoutine;

  /// Delete routine confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteRoutineConfirm(String name);

  /// Create time slot dialog title
  ///
  /// In en, this message translates to:
  /// **'Create Time Slot'**
  String get createTimeSlot;

  /// Edit time slot dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Time Slot'**
  String get editTimeSlot;

  /// Time slot title input label
  ///
  /// In en, this message translates to:
  /// **'Title of this time'**
  String get titleOfThisTime;

  /// Time slot title input hint
  ///
  /// In en, this message translates to:
  /// **'e.g., Work, Exercise, Sleep...'**
  String get titleHint;

  /// Time slot description input label
  ///
  /// In en, this message translates to:
  /// **'Description of this time'**
  String get descriptionOfThisTime;

  /// Time slot description input hint
  ///
  /// In en, this message translates to:
  /// **'e.g., Morning workout routine, Team meeting...'**
  String get descriptionHint;

  /// Adjust time section label
  ///
  /// In en, this message translates to:
  /// **'Adjust time:'**
  String get adjustTime;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'From: '**
  String get from;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'To: '**
  String get to;

  /// Color picker section label
  ///
  /// In en, this message translates to:
  /// **'Choose a color:'**
  String get chooseColor;

  /// Notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Duration display text
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(String duration);

  /// Duration suffix for time slot cards
  ///
  /// In en, this message translates to:
  /// **'{duration} duration'**
  String durationSuffix(String duration);

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark mode label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selector dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Help and support section title
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Tutorial menu item
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// Tutorial description
  ///
  /// In en, this message translates to:
  /// **'Learn how to use the app'**
  String get learnHowToUse;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Developer credit
  ///
  /// In en, this message translates to:
  /// **'Developed By Kwanhoon Lee'**
  String get developedBy;

  /// Copyright notice
  ///
  /// In en, this message translates to:
  /// **'© 2025 - Made For me and YOU'**
  String get copyright;

  /// Language change confirmation message
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(String language);

  /// Tutorial welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Routine 24'**
  String get welcomeToRoutine;

  /// Tutorial welcome description
  ///
  /// In en, this message translates to:
  /// **'Plan your day with our interactive 24-hour clock interface.'**
  String get planYourDay;

  /// Tutorial slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Creating Time Slots'**
  String get creatingTimeSlots;

  /// Tutorial slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Tap and drag on the clock to create time slots for your activities. The outer ring represents hours (0-23).'**
  String get creatingTimeSlotsDesc;

  /// Tutorial slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Managing Your Schedule'**
  String get managingYourSchedule;

  /// Tutorial slide 3 description
  ///
  /// In en, this message translates to:
  /// **'Your time slots will appear with start and end times. Tap on existing slots to modify or delete them.'**
  String get managingYourScheduleDesc;

  /// Tutorial slide 4 title
  ///
  /// In en, this message translates to:
  /// **'Settings & Customization'**
  String get settingsCustomization;

  /// Tutorial slide 4 description
  ///
  /// In en, this message translates to:
  /// **'Tap the settings button in the top-right corner to access theme toggle, language options, and more customization features.'**
  String get settingsCustomizationDesc;

  /// Tutorial slide 5 title
  ///
  /// In en, this message translates to:
  /// **'PRO Subscription Benefits'**
  String get proSubscriptionBenefits;

  /// Tutorial slide 5 description
  ///
  /// In en, this message translates to:
  /// **'Subscribe to PRO for \$6.99/year to unlock unlimited routine slots, ad-free experience, and premium features. Free users get 1 slot.'**
  String get proSubscriptionBenefitsDesc;

  /// Tutorial finish button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Previous button in tutorial
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Next button in tutorial
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Free user limitation message
  ///
  /// In en, this message translates to:
  /// **'Free users can use 1 slot. Upgrade to Pro for unlimited slots.'**
  String get freeUsersOneSlot;

  /// Pro features list header
  ///
  /// In en, this message translates to:
  /// **'Pro features include:'**
  String get proFeatures;

  /// Pro feature: unlimited slots
  ///
  /// In en, this message translates to:
  /// **'• Unlimited routine slots'**
  String get unlimitedSlots;

  /// Pro feature: duplicate routines
  ///
  /// In en, this message translates to:
  /// **'• Duplicate routines'**
  String get duplicateRoutines;

  /// Pro feature: priority support
  ///
  /// In en, this message translates to:
  /// **'• Priority support'**
  String get prioritySupport;

  /// Pro feature: advanced customization
  ///
  /// In en, this message translates to:
  /// **'• Advanced customization'**
  String get advancedCustomization;

  /// Later button text
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Upgrade now button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// Thank you message for pro users
  ///
  /// In en, this message translates to:
  /// **'Thanks for supporting Routine 24! Enjoy unlimited slots and ad-free experience.'**
  String get thanksForSupporting;

  /// Advertisement placeholder text
  ///
  /// In en, this message translates to:
  /// **'Advertisement Space'**
  String get advertisementSpace;

  /// Pro upgrade advertisement text
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for \$6.99/year - No ads, unlimited slots!'**
  String get upgradeToProAd;

  /// Sign in success message
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in!'**
  String get signInSuccess;

  /// Sign out success message
  ///
  /// In en, this message translates to:
  /// **'Successfully signed out'**
  String get signOutSuccess;

  /// Account creation success message
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccess;

  /// Password mismatch error message
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Password minimum length error message
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Upgrade to pro for unlimited slots message
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for unlimited slots'**
  String get upgradeToProUnlimited;

  /// Media not found placeholder text
  ///
  /// In en, this message translates to:
  /// **'Media not found'**
  String get mediaNotFound;

  /// Or separator text
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Default routine name for new users
  ///
  /// In en, this message translates to:
  /// **'Default Routine'**
  String get defaultRoutine;
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
      <String>['en', 'es', 'ko', 'zh'].contains(locale.languageCode);

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
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
