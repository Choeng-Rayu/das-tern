import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
    Locale('km')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DasTern'**
  String get appTitle;

  /// Create a new account
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccount;

  /// Last name or surname label
  ///
  /// In en, this message translates to:
  /// **'Last name / Surname'**
  String get lastName;

  /// Prompt to fill in last name
  ///
  /// In en, this message translates to:
  /// **'Please fill in your last name'**
  String get fillLastName;

  /// First name or given name label
  ///
  /// In en, this message translates to:
  /// **'First name / Given name'**
  String get firstName;

  /// Prompt to fill in first name
  ///
  /// In en, this message translates to:
  /// **'Please fill in your first name'**
  String get fillFirstName;

  /// Gender label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Prompt to fill in gender
  ///
  /// In en, this message translates to:
  /// **'Please fill in your gender'**
  String get fillGender;

  /// Date of birth label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// Day label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Month label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Year label
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// ID card or identification number label
  ///
  /// In en, this message translates to:
  /// **'ID card number / Identification number'**
  String get idCardNumber;

  /// Prompt to fill in ID card number
  ///
  /// In en, this message translates to:
  /// **'Please fill in your ID card number'**
  String get fillIdCardNumber;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Already created account label
  ///
  /// In en, this message translates to:
  /// **'Already created an account before'**
  String get alreadyCreatedAccount;

  /// Go back button label
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Phone number label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Prompt to fill in phone number
  ///
  /// In en, this message translates to:
  /// **'Please fill in your phone number'**
  String get fillPhoneNumber;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Prompt to fill in password
  ///
  /// In en, this message translates to:
  /// **'Please fill in your password'**
  String get fillPassword;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Prompt to fill in password again
  ///
  /// In en, this message translates to:
  /// **'Please fill in your password again'**
  String get fillConfirmPassword;

  /// 4-digit PIN code label
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN code'**
  String get pinCode;

  /// Prompt to read terms and conditions
  ///
  /// In en, this message translates to:
  /// **'Please read the terms and conditions before using the application'**
  String get readTerms;

  /// Already read confirmation label
  ///
  /// In en, this message translates to:
  /// **'Already read / I have read'**
  String get alreadyRead;

  /// Sign in or log in label
  ///
  /// In en, this message translates to:
  /// **'Log in to account / Sign in'**
  String get signIn;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Title shown on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to DasTern'**
  String get welcomeTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Your medication reminder companion'**
  String get welcomeMessage;

  /// Button to start using the app
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Medicine list screen title
  ///
  /// In en, this message translates to:
  /// **'Medicine List'**
  String get medicineList;

  /// Add medicine button
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// Edit medicine title
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get editMedicine;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Khmer language option
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// Message when medicine list is empty
  ///
  /// In en, this message translates to:
  /// **'No medicines added yet'**
  String get noMedicines;

  /// Medicine name field label
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button or label for logging in as a doctor
  ///
  /// In en, this message translates to:
  /// **'Login as a Doctor'**
  String get loginAsDoctor;

  /// Button or label for signing in (already have an account)
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signin;

  /// Create account message
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Greeting
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// Today's schedule title
  ///
  /// In en, this message translates to:
  /// **'Schedule (Today)'**
  String get todaySchedule;

  /// Dose/pill label
  ///
  /// In en, this message translates to:
  /// **'dose'**
  String get dose;

  /// Patient label
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number or password'**
  String get loginError;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registerSuccess;

  /// Welcome back message on login
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Medications screen title
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// Add medication button
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// Edit medication title
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// Delete medication confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// Delete medication confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteMedicationMessage;

  /// Medication deleted success message
  ///
  /// In en, this message translates to:
  /// **'Medication deleted successfully'**
  String get medicationDeleted;

  /// Medication added success message
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get medicationAdded;

  /// Medication updated success message
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully'**
  String get medicationUpdated;

  /// Medication name field
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// Dosage field
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Unit field
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Tablet unit
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// Milliliter unit
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get ml;

  /// Milligram unit
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get mg;

  /// Other unit
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Instruction field
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// Prescribed by field
  ///
  /// In en, this message translates to:
  /// **'Prescribed By'**
  String get prescribedBy;

  /// Reminders section title
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Auto-generate reminders option
  ///
  /// In en, this message translates to:
  /// **'Auto-generate 3 daily reminders'**
  String get autoGenerateReminders;

  /// Reminders generated success message
  ///
  /// In en, this message translates to:
  /// **'Reminders generated successfully'**
  String get remindersGenerated;

  /// Morning time
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// Afternoon time
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// Evening time
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// Night time
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Medication name hint
  ///
  /// In en, this message translates to:
  /// **'Enter medication name'**
  String get enterMedicationName;

  /// Amount hint
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// Instruction hint
  ///
  /// In en, this message translates to:
  /// **'Enter usage instructions'**
  String get enterInstruction;

  /// Prescriber hint
  ///
  /// In en, this message translates to:
  /// **'Enter prescriber name'**
  String get enterPrescriber;

  /// Required field validation message
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Empty medications list message
  ///
  /// In en, this message translates to:
  /// **'No medications added yet'**
  String get noMedications;

  /// Today's reminders title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reminders'**
  String get todayReminders;

  /// Upcoming reminders section
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingReminders;

  /// Completed reminders section
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReminders;

  /// Mark medication as taken button
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Taken status
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// Missed status
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// Skipped status
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Intake history title
  ///
  /// In en, this message translates to:
  /// **'Intake History'**
  String get intakeHistory;

  /// Adherence rate label
  ///
  /// In en, this message translates to:
  /// **'Adherence Rate'**
  String get adherenceRate;

  /// This week filter
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// This month filter
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// All filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Taken at time label
  ///
  /// In en, this message translates to:
  /// **'Taken at'**
  String get takenAt;

  /// Scheduled time label
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// Empty history message
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// View history button
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No reminders message
  ///
  /// In en, this message translates to:
  /// **'No reminders for today'**
  String get noRemindersToday;

  /// Manage reminders button
  ///
  /// In en, this message translates to:
  /// **'Manage Reminders'**
  String get manageReminders;

  /// Edit reminder title
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// Delete reminder confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Days label
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Add time button
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// No reminders added message
  ///
  /// In en, this message translates to:
  /// **'No reminder times added yet. Tap \'Add Time\' to set medication schedule.'**
  String get noRemindersAdded;

  /// Time of day label
  ///
  /// In en, this message translates to:
  /// **'Time of Day'**
  String get timeOfDay;

  /// Dosage amount label
  ///
  /// In en, this message translates to:
  /// **'Dosage Amount'**
  String get dosageAmount;

  /// Active days label
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// Reminder validation message
  ///
  /// In en, this message translates to:
  /// **'Please add at least one reminder time'**
  String get addAtLeastOneReminder;

  /// Reminder label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// Delayed status - taken late
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// View all button
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Quick stats section title
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// Today's medications section
  ///
  /// In en, this message translates to:
  /// **'Today\'s Medications'**
  String get todayMedications;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Date of birth placeholder
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectDateOfBirth;

  /// Blood type label
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// Family contact label
  ///
  /// In en, this message translates to:
  /// **'Family Contact'**
  String get familyContact;

  /// Weight label
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get address;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// Password length error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Phone required error
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// Phone invalid error
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneInvalid;

  /// Password required error
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// Name required error
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// Date of birth required error
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get pleaseSelectDateOfBirth;

  /// Blood type required error
  ///
  /// In en, this message translates to:
  /// **'Please select blood type'**
  String get pleaseSelectBloodType;

  /// Family contact required error
  ///
  /// In en, this message translates to:
  /// **'Please enter family contact'**
  String get pleaseEnterFamilyContact;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Phone number hint
  ///
  /// In en, this message translates to:
  /// **'012345678'**
  String get enterPhoneHint;

  /// Password hint
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get enterPasswordHint;

  /// Name hint
  ///
  /// In en, this message translates to:
  /// **'Kimhour'**
  String get enterNameHint;

  /// Family contact hint
  ///
  /// In en, this message translates to:
  /// **'098765432'**
  String get enterFamilyContactHint;

  /// Weight hint
  ///
  /// In en, this message translates to:
  /// **'60.0'**
  String get enterWeightHint;

  /// Address hint
  ///
  /// In en, this message translates to:
  /// **'Street, District, Province'**
  String get enterAddressHint;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
