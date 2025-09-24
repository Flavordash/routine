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

  /// Button text to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
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
  /// **'Subscribe to PRO for \$7.99/year to unlock unlimited routine slots, ad-free experience, community template sharing, advanced alarms, cloud sync, and more premium features. Free users get 1 slot.'**
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
  /// **'Upgrade to Pro for \$7.99/year - No ads, unlimited slots!'**
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

  /// Pro feature: schedule for specific days (full text)
  ///
  /// In en, this message translates to:
  /// **'Schedule routine for specific days (Mon-Sun)'**
  String get scheduleSpecificDaysFull;

  /// Pro feature: advanced notifications (full text)
  ///
  /// In en, this message translates to:
  /// **'Advanced notification with vibration'**
  String get advancedNotificationsFull;

  /// Pro upgrade call to action
  ///
  /// In en, this message translates to:
  /// **'Get Unlimited Access'**
  String get getUnlimitedAccess;

  /// Pro feature: remove all ads
  ///
  /// In en, this message translates to:
  /// **'Remove all advertisements'**
  String get removeAllAds;

  /// Pro feature: schedule specific days
  ///
  /// In en, this message translates to:
  /// **'Schedule Specific Days'**
  String get scheduleSpecificDays;

  /// Pro feature: advanced notifications
  ///
  /// In en, this message translates to:
  /// **'Advanced Notifications'**
  String get advancedNotifications;

  /// Pro feature: cloud sync and backup
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync & Backup'**
  String get cloudSyncBackup;

  /// Subscription plan selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// Monthly subscription plan
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get monthlyPlan;

  /// Monthly subscription price
  ///
  /// In en, this message translates to:
  /// **'\$3.99/month'**
  String get monthlyPrice;

  /// Yearly subscription plan
  ///
  /// In en, this message translates to:
  /// **'Yearly Plan'**
  String get yearlyPlan;

  /// Yearly subscription price
  ///
  /// In en, this message translates to:
  /// **'\$7.99/year'**
  String get yearlyPrice;

  /// Savings text for yearly plan
  ///
  /// In en, this message translates to:
  /// **'Save 42%'**
  String get savingsText;

  /// Restore purchases button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Popular plan badge
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// Purchase processing message
  ///
  /// In en, this message translates to:
  /// **'Processing Purchase...'**
  String get processingPurchase;

  /// Purchase processing placeholder text
  ///
  /// In en, this message translates to:
  /// **'Processing your purchase. Please wait...'**
  String get purchasePlaceholder;

  /// Restore processing placeholder text
  ///
  /// In en, this message translates to:
  /// **'Restoring your purchases. Please wait...'**
  String get restorePlaceholder;

  /// Pro feature: share templates to community
  ///
  /// In en, this message translates to:
  /// **'• Share your own templates to the community'**
  String get shareTemplates;

  /// Pro feature: advanced alarm features
  ///
  /// In en, this message translates to:
  /// **'• Advanced alarm features with pre-alarm and Smart Intervals'**
  String get advancedAlarmFeatures;

  /// Pro feature: browse and import templates
  ///
  /// In en, this message translates to:
  /// **'• Browse and import community templates'**
  String get browseImportTemplates;

  /// Pro feature: remove all ads (full text)
  ///
  /// In en, this message translates to:
  /// **'• Remove all ads'**
  String get removeAllAdsFull;

  /// Pro feature: cloud sync and backup (full text)
  ///
  /// In en, this message translates to:
  /// **'• Cloud sync and backup'**
  String get cloudSyncBackupFull;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notification permissions title
  ///
  /// In en, this message translates to:
  /// **'Notification Permissions'**
  String get notificationPermissions;

  /// Status when notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get notificationsEnabled;

  /// Status when notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get notificationsDisabled;

  /// Button text for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Description of why notification permissions are needed
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive alarms and reminders for your routines'**
  String get notificationPermissionDescription;

  /// Button text to open device settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Message when notification permissions are granted
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled! You\'ll receive alarms for your routines.'**
  String get notificationPermissionGranted;

  /// Message when notification permissions are denied
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in your device settings to receive alarms.'**
  String get notificationPermissionDenied;

  /// PRO feature: Pre-alarm setting label
  ///
  /// In en, this message translates to:
  /// **'Pre-Alarm'**
  String get preAlarm;

  /// PRO feature: Pre-alarm time setting label
  ///
  /// In en, this message translates to:
  /// **'Pre-alarm time:'**
  String get preAlarmTime;

  /// PRO feature: Smart Intervals setting label
  ///
  /// In en, this message translates to:
  /// **'Smart Intervals'**
  String get smartIntervals;

  /// PRO feature: Smart Intervals duration setting label
  ///
  /// In en, this message translates to:
  /// **'Interval Duration:'**
  String get intervalDuration;

  /// PRO feature: Silent intervals setting label
  ///
  /// In en, this message translates to:
  /// **'Silent Intervals'**
  String get silentIntervals;

  /// PRO feature: Progress messages setting label
  ///
  /// In en, this message translates to:
  /// **'Progress Messages'**
  String get progressMessages;

  /// Short format for minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// Count format for attempts
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String timesCount(int count);

  /// PRO upgrade promotion text for advanced alarm features
  ///
  /// In en, this message translates to:
  /// **'Get advanced alarm features with pre-alarm warnings and Smart Intervals functionality.'**
  String get advancedAlarmPromoText;

  /// Button text to fill empty time slots with free time
  ///
  /// In en, this message translates to:
  /// **'Fill Free Time'**
  String get fillFreeTime;

  /// Button text to browse template gallery
  ///
  /// In en, this message translates to:
  /// **'Browse Templates'**
  String get browseTemplates;

  /// Success message when filling free time
  ///
  /// In en, this message translates to:
  /// **'Filled 24-hour period with Free Time!'**
  String get filledFreeTime;

  /// Message when no gaps available to fill
  ///
  /// In en, this message translates to:
  /// **'No free time gaps found to fill'**
  String get noFreeTimeGaps;

  /// Purchase success message
  ///
  /// In en, this message translates to:
  /// **'Purchase successful! You now have PRO access.'**
  String get purchaseSuccessful;

  /// Purchase failure message
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String purchaseFailed(String error);

  /// Purchase restoration success message
  ///
  /// In en, this message translates to:
  /// **'Purchases restored successfully!'**
  String get purchasesRestored;

  /// Purchase restoration failure message
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// Monday day name
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday day name
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday day name
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday day name
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday day name
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday day name
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday day name
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Instruction text for day selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select which days this routine should be active:'**
  String get selectDaysActive;

  /// Sort option for newest templates
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Sort option for most liked templates
  ///
  /// In en, this message translates to:
  /// **'Most Liked'**
  String get mostLiked;

  /// Sort option for most used templates
  ///
  /// In en, this message translates to:
  /// **'Most Used'**
  String get mostUsed;

  /// Placeholder text for template search
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get searchPlaceholder;

  /// Category filter label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Lifestyle filter label
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyle;

  /// Sort filter label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Loading message for templates
  ///
  /// In en, this message translates to:
  /// **'Loading templates...'**
  String get loadingTemplates;

  /// Message when no templates match filters
  ///
  /// In en, this message translates to:
  /// **'No templates found'**
  String get noTemplatesFound;

  /// Button to clear all filters
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Message when no templates exist
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplatesAvailable;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Template category display text
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String templateCategory(String category);

  /// Template loading error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load some templates: {error}'**
  String failedToLoadTemplates(String error);

  /// All items filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Color settings menu item
  ///
  /// In en, this message translates to:
  /// **'Color Settings'**
  String get colorSettings;

  /// Share as template menu item
  ///
  /// In en, this message translates to:
  /// **'Share as Template'**
  String get shareAsTemplate;

  /// Day settings menu item
  ///
  /// In en, this message translates to:
  /// **'Day Settings'**
  String get daySettings;

  /// Rename routine dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename Routine'**
  String get renameRoutineDialog;

  /// Delete routine dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get deleteRoutineDialog;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteConfirmMessage(String name);

  /// Day settings dialog title
  ///
  /// In en, this message translates to:
  /// **'Day Settings for {name}'**
  String daySettingsFor(String name);

  /// Color chooser dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Color for {name}'**
  String chooseColorFor(String name);

  /// Default color option
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultColor;

  /// Template name field label
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Template name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter template name...'**
  String get enterTemplateName;

  /// Template description field placeholder
  ///
  /// In en, this message translates to:
  /// **'Describe this routine...'**
  String get describeRoutine;

  /// Lifestyle type field label
  ///
  /// In en, this message translates to:
  /// **'Lifestyle Type'**
  String get lifestyleType;

  /// Template sharing progress message
  ///
  /// In en, this message translates to:
  /// **'Sharing template...'**
  String get sharingTemplate;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Template name required error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a template name'**
  String get pleaseEnterTemplateName;

  /// Template sharing success message
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" shared successfully!'**
  String templateSharedSuccess(String name);

  /// Template sharing failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to share template. Please try again.'**
  String get templateShareFailed;

  /// Every day text for routine slots
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No days selected text for routine slots
  ///
  /// In en, this message translates to:
  /// **'No days selected'**
  String get noDaysSelected;

  /// Short format for hours
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// Short format for minutes
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShortFormat;
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
