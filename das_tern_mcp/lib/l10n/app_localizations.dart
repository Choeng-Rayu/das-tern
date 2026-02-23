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
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DasTern'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Medication Companion'**
  String get appTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your medication reminder companion'**
  String get welcomeMessage;

  /// No description provided for @selectRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'I am...'**
  String get selectRoleTitle;

  /// No description provided for @selectRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your role to get started'**
  String get selectRoleSubtitle;

  /// No description provided for @patientRole.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientRole;

  /// No description provided for @patientRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Track medication, set reminders, and manage prescriptions.'**
  String get patientRoleDescription;

  /// No description provided for @doctorRole.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorRole;

  /// No description provided for @doctorRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage patients, create prescriptions, and monitor medication intake.'**
  String get doctorRoleDescription;

  /// No description provided for @doctorRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Registration'**
  String get doctorRegistrationTitle;

  /// No description provided for @doctorRegistrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in your information to create a doctor account'**
  String get doctorRegistrationSubtitle;

  /// No description provided for @personalInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoSection;

  /// No description provided for @professionalInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Professional Information'**
  String get professionalInfoSection;

  /// No description provided for @accountSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecuritySection;

  /// No description provided for @accountVerificationInfo.
  ///
  /// In en, this message translates to:
  /// **'Your account will be verified by our team.'**
  String get accountVerificationInfo;

  /// No description provided for @step1PersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 - Personal Information'**
  String get step1PersonalInfo;

  /// No description provided for @step2AccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 - Account Information'**
  String get step2AccountInfo;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @fillLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get fillLastNameHint;

  /// No description provided for @fillLastNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get fillLastNameError;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @fillFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get fillFirstNameHint;

  /// No description provided for @fillFirstNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get fillFirstNameError;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dateFormatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get dateFormatPlaceholder;

  /// No description provided for @pleaseSelectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get pleaseSelectDateOfBirth;

  /// No description provided for @idCardNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Card Number'**
  String get idCardNumber;

  /// No description provided for @idCardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID card number'**
  String get idCardNumberHint;

  /// No description provided for @idCardNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your ID card number'**
  String get idCardNumberError;

  /// No description provided for @idCardOptional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get idCardOptional;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneNumberHint;

  /// No description provided for @phoneNumberEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get phoneNumberEmpty;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneNumberInvalid;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @fullNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter full name'**
  String get fullNameError;

  /// No description provided for @hospitalClinic.
  ///
  /// In en, this message translates to:
  /// **'Hospital / Clinic'**
  String get hospitalClinic;

  /// No description provided for @hospitalClinicHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your hospital or clinic'**
  String get hospitalClinicHint;

  /// No description provided for @hospitalClinicError.
  ///
  /// In en, this message translates to:
  /// **'Please enter hospital'**
  String get hospitalClinicError;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @specialtyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. General Medicine, Cardiology'**
  String get specialtyHint;

  /// No description provided for @specialtyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter specialty'**
  String get specialtyError;

  /// No description provided for @medicalLicense.
  ///
  /// In en, this message translates to:
  /// **'Medical License Number'**
  String get medicalLicense;

  /// No description provided for @medicalLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your license number'**
  String get medicalLicenseHint;

  /// No description provided for @medicalLicenseError.
  ///
  /// In en, this message translates to:
  /// **'Please enter license number'**
  String get medicalLicenseError;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordEmpty;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters required'**
  String get passwordTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'Please read the terms and conditions before using the app'**
  String get termsNotice;

  /// No description provided for @termsRead.
  ///
  /// In en, this message translates to:
  /// **'Already read'**
  String get termsRead;

  /// No description provided for @verifyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCodeTitle;

  /// No description provided for @otpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a 4-digit code to'**
  String get otpSentMessage;

  /// No description provided for @otpFillError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 4-digit code'**
  String get otpFillError;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DasTern'**
  String get welcomeTitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @unlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features'**
  String get unlockPremiumFeatures;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @todayMedications.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Medications'**
  String get todayMedications;

  /// No description provided for @todayReminders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reminders'**
  String get todayReminders;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @noRemindersToday.
  ///
  /// In en, this message translates to:
  /// **'No reminders for today'**
  String get noRemindersToday;

  /// No description provided for @medicineList.
  ///
  /// In en, this message translates to:
  /// **'Medicine List'**
  String get medicineList;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get editMedicine;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines added yet'**
  String get noMedicines;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// No description provided for @deleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// No description provided for @deleteMedicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteMedicationMessage;

  /// No description provided for @createMedication.
  ///
  /// In en, this message translates to:
  /// **'Create Medication'**
  String get createMedication;

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications added yet'**
  String get noMedications;

  /// No description provided for @medicationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Medication deleted successfully'**
  String get medicationDeleted;

  /// No description provided for @medicationAdded.
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get medicationAdded;

  /// No description provided for @medicationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully'**
  String get medicationUpdated;

  /// No description provided for @medicationCreated.
  ///
  /// In en, this message translates to:
  /// **'Medication created successfully'**
  String get medicationCreated;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @dosageAmount.
  ///
  /// In en, this message translates to:
  /// **'Dosage Amount'**
  String get dosageAmount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @form.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get form;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @dose.
  ///
  /// In en, this message translates to:
  /// **'dose'**
  String get dose;

  /// No description provided for @timesPerDay.
  ///
  /// In en, this message translates to:
  /// **'times per day'**
  String get timesPerDay;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @liquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get liquid;

  /// No description provided for @ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get ml;

  /// No description provided for @mg.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get mg;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @prn.
  ///
  /// In en, this message translates to:
  /// **'As Needed (PRN)'**
  String get prn;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @prescribedBy.
  ///
  /// In en, this message translates to:
  /// **'Prescribed By'**
  String get prescribedBy;

  /// No description provided for @enterMedicationName.
  ///
  /// In en, this message translates to:
  /// **'Enter medication name'**
  String get enterMedicationName;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter usage instructions'**
  String get enterInstruction;

  /// No description provided for @enterPrescriber.
  ///
  /// In en, this message translates to:
  /// **'Enter prescriber name'**
  String get enterPrescriber;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @manageReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage Reminders'**
  String get manageReminders;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// No description provided for @autoGenerateReminders.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate 3 daily reminders'**
  String get autoGenerateReminders;

  /// No description provided for @remindersGenerated.
  ///
  /// In en, this message translates to:
  /// **'Reminders generated successfully'**
  String get remindersGenerated;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set successfully'**
  String get reminderSet;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// No description provided for @noRemindersAdded.
  ///
  /// In en, this message translates to:
  /// **'No reminder times added yet. Tap \'Add Time\' to set medication schedule.'**
  String get noRemindersAdded;

  /// No description provided for @addAtLeastOneReminder.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one reminder time'**
  String get addAtLeastOneReminder;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @daytime.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get daytime;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of Day'**
  String get timeOfDay;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// No description provided for @markAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// No description provided for @markedAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Marked as taken'**
  String get markedAsTaken;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @takenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken at'**
  String get takenAt;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingReminders;

  /// No description provided for @completedReminders.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReminders;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @intakeHistory.
  ///
  /// In en, this message translates to:
  /// **'Intake History'**
  String get intakeHistory;

  /// No description provided for @adherenceRate.
  ///
  /// In en, this message translates to:
  /// **'Adherence Rate'**
  String get adherenceRate;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @loginAsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Login as Doctor'**
  String get loginAsDoctor;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @familyContact.
  ///
  /// In en, this message translates to:
  /// **'Family Contact'**
  String get familyContact;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get address;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseSelectBloodType.
  ///
  /// In en, this message translates to:
  /// **'Please select blood type'**
  String get pleaseSelectBloodType;

  /// No description provided for @pleaseEnterFamilyContact.
  ///
  /// In en, this message translates to:
  /// **'Please enter family contact'**
  String get pleaseEnterFamilyContact;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number or password'**
  String get loginError;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registerSuccess;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'012345678'**
  String get enterPhoneHint;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get enterPasswordHint;

  /// No description provided for @enterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Kimhour'**
  String get enterNameHint;

  /// No description provided for @enterFamilyContactHint.
  ///
  /// In en, this message translates to:
  /// **'098765432'**
  String get enterFamilyContactHint;

  /// No description provided for @enterWeightHint.
  ///
  /// In en, this message translates to:
  /// **'60.0'**
  String get enterWeightHint;

  /// No description provided for @enterAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, District, Province'**
  String get enterAddressHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @medicationsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsAnalysis;

  /// No description provided for @scanPrescriptionTab.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanPrescriptionTab;

  /// No description provided for @familyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyFeatures;

  /// No description provided for @greetingName.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}!'**
  String greetingName(String name);

  /// No description provided for @defaultPatientName.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get defaultPatientName;

  /// No description provided for @medicationTracker.
  ///
  /// In en, this message translates to:
  /// **'Medication Tracker'**
  String get medicationTracker;

  /// No description provided for @beforeMeal.
  ///
  /// In en, this message translates to:
  /// **'Before meal'**
  String get beforeMeal;

  /// No description provided for @medicineCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} medicine(s)'**
  String medicineCountLabel(int count);

  /// No description provided for @progressMessage.
  ///
  /// In en, this message translates to:
  /// **'Medicine intake progress'**
  String get progressMessage;

  /// No description provided for @dayProgress.
  ///
  /// In en, this message translates to:
  /// **'Day {days} completed'**
  String dayProgress(int days);

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total medication period 30 days'**
  String get totalDuration;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks (Today)'**
  String get todaysTasks;

  /// No description provided for @allCompleted.
  ///
  /// In en, this message translates to:
  /// **'All completed!'**
  String get allCompleted;

  /// No description provided for @noMoreMedicationsToday.
  ///
  /// In en, this message translates to:
  /// **'No more medications for today'**
  String get noMoreMedicationsToday;

  /// No description provided for @searchPrescription.
  ///
  /// In en, this message translates to:
  /// **'Search prescriptions'**
  String get searchPrescription;

  /// No description provided for @medicationIntakeHistory.
  ///
  /// In en, this message translates to:
  /// **'Medication\nintake history'**
  String get medicationIntakeHistory;

  /// No description provided for @healthVitals.
  ///
  /// In en, this message translates to:
  /// **'Health Vitals'**
  String get healthVitals;

  /// No description provided for @thresholds.
  ///
  /// In en, this message translates to:
  /// **'Thresholds'**
  String get thresholds;

  /// No description provided for @emergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyLabel;

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordLabel;

  /// No description provided for @onePill.
  ///
  /// In en, this message translates to:
  /// **'1 pill'**
  String get onePill;

  /// No description provided for @unresolvedAlerts.
  ///
  /// In en, this message translates to:
  /// **'{count} unresolved health alert(s)'**
  String unresolvedAlerts(int count);

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @noActivePrescriptions.
  ///
  /// In en, this message translates to:
  /// **'No active prescriptions'**
  String get noActivePrescriptions;

  /// No description provided for @prescriptionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your prescriptions will appear here\nonce added by your doctor.'**
  String get prescriptionsAppearHere;

  /// No description provided for @medicationCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} medication(s)'**
  String medicationCountLabel(int count);

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @oldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter old password'**
  String get oldPasswordHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// No description provided for @passwordChangeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Password change coming soon'**
  String get passwordChangeComingSoon;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myCaregivers.
  ///
  /// In en, this message translates to:
  /// **'My Caregivers'**
  String get myCaregivers;

  /// No description provided for @patientsIMonitor.
  ///
  /// In en, this message translates to:
  /// **'Patients I monitor'**
  String get patientsIMonitor;

  /// No description provided for @noConnections.
  ///
  /// In en, this message translates to:
  /// **'No connections'**
  String get noConnections;

  /// No description provided for @connectWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Connect with family to\nmonitor medication intake'**
  String get connectWithFamily;

  /// No description provided for @connectNow.
  ///
  /// In en, this message translates to:
  /// **'Connect Now'**
  String get connectNow;

  /// No description provided for @viewAllConnections.
  ///
  /// In en, this message translates to:
  /// **'View All Connections'**
  String get viewAllConnections;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @waitingStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waitingStatus;

  /// No description provided for @gracePeriodSettings.
  ///
  /// In en, this message translates to:
  /// **'Grace Period Settings'**
  String get gracePeriodSettings;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @scanPrescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Prescription'**
  String get scanPrescriptionTitle;

  /// No description provided for @scanPrescriptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to scan a prescription\nfrom your doctor.'**
  String get scanPrescriptionDescription;

  /// No description provided for @openScanner.
  ///
  /// In en, this message translates to:
  /// **'Open Scanner'**
  String get openScanner;

  /// No description provided for @scannerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scanner feature coming soon'**
  String get scannerComingSoon;

  /// No description provided for @scanFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scanFromCamera;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get scanFromGallery;

  /// No description provided for @scanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Scanning prescription...'**
  String get scanProcessing;

  /// No description provided for @scanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Prescription scanned successfully!'**
  String get scanSuccess;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed. Please try again.'**
  String get scanFailed;

  /// No description provided for @scanMedicationsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} medications found'**
  String scanMedicationsFound(int count);

  /// No description provided for @doseHistoryAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your dose history will appear here.'**
  String get doseHistoryAppearHere;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @allFeaturesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'All features unlocked'**
  String get allFeaturesUnlocked;

  /// No description provided for @upgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock all features'**
  String get upgradeToUnlock;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @myConnections.
  ///
  /// In en, this message translates to:
  /// **'My Connections'**
  String get myConnections;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @planNamePlan.
  ///
  /// In en, this message translates to:
  /// **'{name} Plan'**
  String planNamePlan(String name);

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'\${price}/month'**
  String pricePerMonth(String price);

  /// No description provided for @bakongKHQR.
  ///
  /// In en, this message translates to:
  /// **'Bakong (KHQR)'**
  String get bakongKHQR;

  /// No description provided for @payWithCambodiaBank.
  ///
  /// In en, this message translates to:
  /// **'Pay with any Cambodian banking app'**
  String get payWithCambodiaBank;

  /// No description provided for @scanQRWithBank.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code with ABA, ACLEDA, Wing, or any KHQR-supported bank'**
  String get scanQRWithBank;

  /// No description provided for @visaMastercard.
  ///
  /// In en, this message translates to:
  /// **'Visa / Mastercard'**
  String get visaMastercard;

  /// No description provided for @internationalCard.
  ///
  /// In en, this message translates to:
  /// **'International credit or debit card'**
  String get internationalCard;

  /// No description provided for @internationalCardSupport.
  ///
  /// In en, this message translates to:
  /// **'Support for Visa, Mastercard, and other international cards'**
  String get internationalCardSupport;

  /// No description provided for @bakongPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Bakong Payment'**
  String get bakongPaymentTitle;

  /// No description provided for @bakongKHQRPayment.
  ///
  /// In en, this message translates to:
  /// **'Bakong KHQR Payment'**
  String get bakongKHQRPayment;

  /// No description provided for @nationalBankOfCambodia.
  ///
  /// In en, this message translates to:
  /// **'National Bank of Cambodia'**
  String get nationalBankOfCambodia;

  /// No description provided for @planSummary.
  ///
  /// In en, this message translates to:
  /// **'Plan Summary'**
  String get planSummary;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @billingLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingLabel;

  /// No description provided for @monthlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyBilling;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it Works'**
  String get howItWorks;

  /// No description provided for @bakongStep1.
  ///
  /// In en, this message translates to:
  /// **'Click \"Confirm & Get QR Code\" below'**
  String get bakongStep1;

  /// No description provided for @bakongStep2.
  ///
  /// In en, this message translates to:
  /// **'Open your banking app (ABA, ACLEDA, Wing, etc.)'**
  String get bakongStep2;

  /// No description provided for @bakongStep3.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code displayed on screen'**
  String get bakongStep3;

  /// No description provided for @bakongStep4.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment in your banking app'**
  String get bakongStep4;

  /// No description provided for @bakongStep5.
  ///
  /// In en, this message translates to:
  /// **'Your plan will be upgraded automatically'**
  String get bakongStep5;

  /// No description provided for @paymentSecureNotice.
  ///
  /// In en, this message translates to:
  /// **'Your payment is processed securely through the Bakong system by the National Bank of Cambodia.'**
  String get paymentSecureNotice;

  /// No description provided for @confirmAndGetQR.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Get QR Code'**
  String get confirmAndGetQR;

  /// No description provided for @scanToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan to Pay'**
  String get scanToPay;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentExpired.
  ///
  /// In en, this message translates to:
  /// **'Payment Expired'**
  String get paymentExpired;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Payment'**
  String get waitingForPayment;

  /// No description provided for @waitingForPaymentEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment...'**
  String get waitingForPaymentEllipsis;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @howToPay.
  ///
  /// In en, this message translates to:
  /// **'How to Pay'**
  String get howToPay;

  /// No description provided for @howToPayStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open your banking app'**
  String get howToPayStep1;

  /// No description provided for @howToPayStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Select \"Scan QR\" or \"KHQR\"'**
  String get howToPayStep2;

  /// No description provided for @howToPayStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Scan the QR code above'**
  String get howToPayStep3;

  /// No description provided for @howToPayStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Confirm the amount and pay'**
  String get howToPayStep4;

  /// No description provided for @howToPayStep5.
  ///
  /// In en, this message translates to:
  /// **'5. Payment will be verified automatically'**
  String get howToPayStep5;

  /// No description provided for @payWithBankingApp.
  ///
  /// In en, this message translates to:
  /// **'Pay with Banking App'**
  String get payWithBankingApp;

  /// No description provided for @selectYourBank.
  ///
  /// In en, this message translates to:
  /// **'Select Your Bank'**
  String get selectYourBank;

  /// No description provided for @openInBankingApp.
  ///
  /// In en, this message translates to:
  /// **'Open in Banking App'**
  String get openInBankingApp;

  /// No description provided for @bankNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'App not installed. Please scan the QR code instead.'**
  String get bankNotInstalled;

  /// No description provided for @supportedByAllKHQR.
  ///
  /// In en, this message translates to:
  /// **'Supported by all KHQR banks'**
  String get supportedByAllKHQR;

  /// No description provided for @cancelPayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Payment?'**
  String get cancelPayment;

  /// No description provided for @cancelPaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel? Your payment will not be processed.'**
  String get cancelPaymentMessage;

  /// No description provided for @keepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Keep Waiting'**
  String get keepWaiting;

  /// No description provided for @subscriptionUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been upgraded'**
  String get subscriptionUpgraded;

  /// No description provided for @allPremiumFeaturesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'All premium features are now unlocked'**
  String get allPremiumFeaturesUnlocked;

  /// No description provided for @unlimitedPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'∞ Prescriptions'**
  String get unlimitedPrescriptions;

  /// No description provided for @storageAmount.
  ///
  /// In en, this message translates to:
  /// **'20 GB'**
  String get storageAmount;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a Plan'**
  String get choosePlan;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @featureComparison.
  ///
  /// In en, this message translates to:
  /// **'Feature Comparison'**
  String get featureComparison;

  /// No description provided for @prescriptionsFeature.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptionsFeature;

  /// No description provided for @medicinesFeature.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicinesFeature;

  /// No description provided for @familyLinksFeature.
  ///
  /// In en, this message translates to:
  /// **'Family Links'**
  String get familyLinksFeature;

  /// No description provided for @storageFeature.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageFeature;

  /// No description provided for @prioritySupportFeature.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupportFeature;

  /// No description provided for @familyPlanFeature.
  ///
  /// In en, this message translates to:
  /// **'Family Plan'**
  String get familyPlanFeature;

  /// No description provided for @addAtLeastOneMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add at least one medicine'**
  String get addAtLeastOneMedicine;

  /// No description provided for @selfPrescribed.
  ///
  /// In en, this message translates to:
  /// **'Self-prescribed'**
  String get selfPrescribed;

  /// No description provided for @medicineAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Medicine added successfully'**
  String get medicineAddedSuccessfully;

  /// No description provided for @labelPurpose.
  ///
  /// In en, this message translates to:
  /// **'Label / Purpose'**
  String get labelPurpose;

  /// No description provided for @labelPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Daily vitamins'**
  String get labelPurposeHint;

  /// No description provided for @addedMedicines.
  ///
  /// In en, this message translates to:
  /// **'Added Medicines'**
  String get addedMedicines;

  /// No description provided for @saveWithCount.
  ///
  /// In en, this message translates to:
  /// **'Save ({count} medicine(s))'**
  String saveWithCount(int count);

  /// No description provided for @recordVital.
  ///
  /// In en, this message translates to:
  /// **'Record Vital'**
  String get recordVital;

  /// No description provided for @selectVitalType.
  ///
  /// In en, this message translates to:
  /// **'Select Vital Type'**
  String get selectVitalType;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @enterValue.
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get enterValue;

  /// No description provided for @measuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured at'**
  String get measuredAt;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @vitalRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vital recorded successfully'**
  String get vitalRecordedSuccess;

  /// No description provided for @failedToRecordVital.
  ///
  /// In en, this message translates to:
  /// **'Failed to record vital'**
  String get failedToRecordVital;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(String count);

  /// No description provided for @alertThresholds.
  ///
  /// In en, this message translates to:
  /// **'Alert Thresholds'**
  String get alertThresholds;

  /// No description provided for @usingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Using defaults'**
  String get usingDefaults;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'Min ({unit})'**
  String minLabel(String unit);

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max ({unit})'**
  String maxLabel(String unit);

  /// No description provided for @minDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Min Diastolic'**
  String get minDiastolic;

  /// No description provided for @maxDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Max Diastolic'**
  String get maxDiastolic;

  /// No description provided for @confirmEmergency.
  ///
  /// In en, this message translates to:
  /// **'Confirm Emergency'**
  String get confirmEmergency;

  /// No description provided for @confirmEmergencyMessage.
  ///
  /// In en, this message translates to:
  /// **'This will send an emergency alert to all your connected caregivers and doctors. Are you sure?'**
  String get confirmEmergencyMessage;

  /// No description provided for @emergencyAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert Sent'**
  String get emergencyAlertSent;

  /// No description provided for @caregiversNotified.
  ///
  /// In en, this message translates to:
  /// **'All connected caregivers and doctors have been notified.'**
  String get caregiversNotified;

  /// No description provided for @emergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get emergencyAlert;

  /// No description provided for @emergencyAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to alert all your connected caregivers and doctors.'**
  String get emergencyAlertDescription;

  /// No description provided for @messageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get messageOptional;

  /// No description provided for @describeSituation.
  ///
  /// In en, this message translates to:
  /// **'Describe your situation...'**
  String get describeSituation;

  /// No description provided for @emergencyAlertTriggered.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert triggered'**
  String get emergencyAlertTriggered;

  /// No description provided for @doctorPatientsTab.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get doctorPatientsTab;

  /// No description provided for @doctorPrescriptionsTab.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get doctorPrescriptionsTab;

  /// No description provided for @doctorPrescriptionHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get doctorPrescriptionHistoryTab;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @totalPatients.
  ///
  /// In en, this message translates to:
  /// **'Total Patients'**
  String get totalPatients;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'Need Attention'**
  String get needAttention;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @todayAlerts.
  ///
  /// In en, this message translates to:
  /// **'Today Alerts'**
  String get todayAlerts;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @consecutiveMissedDoses.
  ///
  /// In en, this message translates to:
  /// **'{count} consecutive missed doses'**
  String consecutiveMissedDoses(int count);

  /// No description provided for @pendingConnectionRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Connection Requests'**
  String get pendingConnectionRequests;

  /// No description provided for @connectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Connection request'**
  String get connectionRequest;

  /// No description provided for @newPrescription.
  ///
  /// In en, this message translates to:
  /// **'New Prescription'**
  String get newPrescription;

  /// No description provided for @findPatient.
  ///
  /// In en, this message translates to:
  /// **'Find Patient'**
  String get findPatient;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @searchPatients.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatients;

  /// No description provided for @adherenceGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get adherenceGood;

  /// No description provided for @adherenceModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get adherenceModerate;

  /// No description provided for @adherencePoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get adherencePoor;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search.'**
  String get tryDifferentSearch;

  /// No description provided for @connectedPatientsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Connected patients will appear here.'**
  String get connectedPatientsAppearHere;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @noPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions'**
  String get noPrescriptions;

  /// No description provided for @createPrescription.
  ///
  /// In en, this message translates to:
  /// **'Create Prescription'**
  String get createPrescription;

  /// No description provided for @prescriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Prescription History'**
  String get prescriptionHistory;

  /// No description provided for @noPrescriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'No prescription history'**
  String get noPrescriptionHistory;

  /// No description provided for @prescriptionsCreatedAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your created prescriptions\nwill appear here.'**
  String get prescriptionsCreatedAppearHere;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @adherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get adherence;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @failedToLoadPatientDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load patient details'**
  String get failedToLoadPatientDetails;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age: {age} · {gender}'**
  String ageLabel(String age, String gender);

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @activePrescriptionsCount.
  ///
  /// In en, this message translates to:
  /// **'Active Prescriptions ({count})'**
  String activePrescriptionsCount(int count);

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @statusMedicines.
  ///
  /// In en, this message translates to:
  /// **'{status} · {count} medicines'**
  String statusMedicines(String status, int count);

  /// No description provided for @noAdherenceData.
  ///
  /// In en, this message translates to:
  /// **'No adherence data available'**
  String get noAdherenceData;

  /// No description provided for @dailyAdherenceLast30.
  ///
  /// In en, this message translates to:
  /// **'Daily Adherence (Last 30 Days)'**
  String get dailyAdherenceLast30;

  /// No description provided for @dailyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily Breakdown'**
  String get dailyBreakdown;

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addNoteHint;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirmation;

  /// No description provided for @noVitalReadings.
  ///
  /// In en, this message translates to:
  /// **'No vital readings recorded'**
  String get noVitalReadings;

  /// No description provided for @latestReadings.
  ///
  /// In en, this message translates to:
  /// **'Latest Readings'**
  String get latestReadings;

  /// No description provided for @historyCount.
  ///
  /// In en, this message translates to:
  /// **'History ({count})'**
  String historyCount(int count);

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Select Patient'**
  String get selectPatient;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @reviewStep.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStep;

  /// No description provided for @noConnectedPatients.
  ///
  /// In en, this message translates to:
  /// **'No connected patients found.'**
  String get noConnectedPatients;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsLabel;

  /// No description provided for @symptomsRequired.
  ///
  /// In en, this message translates to:
  /// **'Symptoms *'**
  String get symptomsRequired;

  /// No description provided for @diagnosisRequired.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis *'**
  String get diagnosisRequired;

  /// No description provided for @clinicalNote.
  ///
  /// In en, this message translates to:
  /// **'Clinical Note'**
  String get clinicalNote;

  /// No description provided for @followUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUpLabel;

  /// No description provided for @setFollowUpDate.
  ///
  /// In en, this message translates to:
  /// **'Set follow-up date'**
  String get setFollowUpDate;

  /// No description provided for @followUpDateValue.
  ///
  /// In en, this message translates to:
  /// **'Follow-up: {date}'**
  String followUpDateValue(String date);

  /// No description provided for @prescriptionCreated.
  ///
  /// In en, this message translates to:
  /// **'Prescription created'**
  String get prescriptionCreated;

  /// No description provided for @prescriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Prescription Details'**
  String get prescriptionDetails;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License #'**
  String get licenseNumber;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationDays;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @pauseButton.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButton;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// No description provided for @medicineNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name *'**
  String get medicineNameRequired;

  /// No description provided for @medicineNameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Paracetamol'**
  String get medicineNameHintExample;

  /// No description provided for @medicineNameKhmer.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name (Khmer)'**
  String get medicineNameKhmer;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @frequencyRequired.
  ///
  /// In en, this message translates to:
  /// **'Frequency *'**
  String get frequencyRequired;

  /// No description provided for @frequencyHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 times/day'**
  String get frequencyHintExample;

  /// No description provided for @durationDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get durationDaysLabel;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @additionalNote.
  ///
  /// In en, this message translates to:
  /// **'Additional Note'**
  String get additionalNote;

  /// No description provided for @saveMedicine.
  ///
  /// In en, this message translates to:
  /// **'Save Medicine'**
  String get saveMedicine;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @connectFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Family'**
  String get connectFamilyTitle;

  /// No description provided for @shareMedicationWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Share your medication information with family\nso they can help monitor'**
  String get shareMedicationWithFamily;

  /// No description provided for @shareQrCode.
  ///
  /// In en, this message translates to:
  /// **'Share QR Code'**
  String get shareQrCode;

  /// No description provided for @generateCodeForFamily.
  ///
  /// In en, this message translates to:
  /// **'Generate code for family to scan'**
  String get generateCodeForFamily;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @scanCodeFromPatient.
  ///
  /// In en, this message translates to:
  /// **'Scan code from patient to connect'**
  String get scanCodeFromPatient;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get enterCodeManually;

  /// No description provided for @enterEightDigitConnectionCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-digit connection code'**
  String get enterEightDigitConnectionCode;

  /// No description provided for @codeValidFor24Hours.
  ///
  /// In en, this message translates to:
  /// **'Code valid for 24 hours'**
  String get codeValidFor24Hours;

  /// No description provided for @enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCodeTitle;

  /// No description provided for @enterConnectionCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Connection Code'**
  String get enterConnectionCode;

  /// No description provided for @enterEightDigitFromPatient.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 8-digit code from the patient'**
  String get enterEightDigitFromPatient;

  /// No description provided for @codeHintPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'XXXXXXXX'**
  String get codeHintPlaceholder;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a code'**
  String get pleaseEnterCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @scanQrInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code instead'**
  String get scanQrInstead;

  /// No description provided for @connectionCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Code'**
  String get connectionCodeTitle;

  /// No description provided for @failedToGenerateToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate token'**
  String get failedToGenerateToken;

  /// No description provided for @tokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get tokenExpired;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m remaining'**
  String timeRemaining(int hours, int minutes);

  /// No description provided for @cannotGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Cannot generate code'**
  String get cannotGenerateCode;

  /// No description provided for @orUseCode.
  ///
  /// In en, this message translates to:
  /// **'Or use code'**
  String get orUseCode;

  /// No description provided for @instructionStep1Family.
  ///
  /// In en, this message translates to:
  /// **'Open app on family member\'s phone'**
  String get instructionStep1Family;

  /// No description provided for @instructionStep2Family.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Scan QR Code\" or \"Enter Code\"'**
  String get instructionStep2Family;

  /// No description provided for @instructionStep3Family.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code or enter the code'**
  String get instructionStep3Family;

  /// No description provided for @shareCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCodeButton;

  /// No description provided for @shareCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'DasTern connection code: {token}'**
  String shareCodeMessage(String token);

  /// No description provided for @generateNewCode.
  ///
  /// In en, this message translates to:
  /// **'Generate New Code'**
  String get generateNewCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @connectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionTitle;

  /// No description provided for @invalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid token'**
  String get invalidToken;

  /// No description provided for @tokenInvalidOrExpired.
  ///
  /// In en, this message translates to:
  /// **'Token is invalid or expired'**
  String get tokenInvalidOrExpired;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccess;

  /// No description provided for @failedToConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get failedToConnect;

  /// No description provided for @codeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Code'**
  String get codeInvalid;

  /// No description provided for @codeValidTitle.
  ///
  /// In en, this message translates to:
  /// **'Code Valid!'**
  String get codeValidTitle;

  /// No description provided for @connectionRequiresApproval.
  ///
  /// In en, this message translates to:
  /// **'This connection will require patient approval'**
  String get connectionRequiresApproval;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabel;

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @connectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Connection History'**
  String get connectionHistory;

  /// No description provided for @filterAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get filterAccepted;

  /// No description provided for @filterRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get filterRevoked;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistoryFound;

  /// No description provided for @connectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionLabel;

  /// No description provided for @myFamily.
  ///
  /// In en, this message translates to:
  /// **'My Family'**
  String get myFamily;

  /// No description provided for @caregiversTab.
  ///
  /// In en, this message translates to:
  /// **'Caregivers'**
  String get caregiversTab;

  /// No description provided for @patientsTab.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsTab;

  /// No description provided for @newConnection.
  ///
  /// In en, this message translates to:
  /// **'New Connection'**
  String get newConnection;

  /// No description provided for @noCaregiversYet.
  ///
  /// In en, this message translates to:
  /// **'No caregivers yet'**
  String get noCaregiversYet;

  /// No description provided for @shareQrToAllowFamily.
  ///
  /// In en, this message translates to:
  /// **'Share QR code to allow family members\nto monitor medication adherence'**
  String get shareQrToAllowFamily;

  /// No description provided for @notMonitoringPatients.
  ///
  /// In en, this message translates to:
  /// **'Not monitoring any patients'**
  String get notMonitoringPatients;

  /// No description provided for @scanQrToStartMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code from patient to start\nmonitoring medication adherence'**
  String get scanQrToStartMonitoring;

  /// No description provided for @caregiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiverLabel;

  /// No description provided for @statusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get statusRevoked;

  /// No description provided for @accessLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Level'**
  String get accessLevelTitle;

  /// No description provided for @selectAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'Select Access Level'**
  String get selectAccessLevel;

  /// No description provided for @accessLevelChangeableLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this level later'**
  String get accessLevelChangeableLater;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// No description provided for @viewOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Caregiver can only view medication schedules'**
  String get viewOnlyDescription;

  /// No description provided for @viewAndRemind.
  ///
  /// In en, this message translates to:
  /// **'View + Remind'**
  String get viewAndRemind;

  /// No description provided for @viewAndRemindDescription.
  ///
  /// In en, this message translates to:
  /// **'Caregiver can view and send nudge reminders'**
  String get viewAndRemindDescription;

  /// No description provided for @viewAndManage.
  ///
  /// In en, this message translates to:
  /// **'View + Manage'**
  String get viewAndManage;

  /// No description provided for @viewAndManageDescription.
  ///
  /// In en, this message translates to:
  /// **'Caregiver can view, remind and edit schedules'**
  String get viewAndManageDescription;

  /// No description provided for @connectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Connection not found'**
  String get connectionNotFound;

  /// No description provided for @disconnectConnection.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Connection'**
  String get disconnectConnection;

  /// No description provided for @todayMedicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Medication Schedule'**
  String get todayMedicationSchedule;

  /// No description provided for @noMedicationData.
  ///
  /// In en, this message translates to:
  /// **'No medication data'**
  String get noMedicationData;

  /// No description provided for @connectionConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionConnected;

  /// No description provided for @missedDosesSection.
  ///
  /// In en, this message translates to:
  /// **'Missed Doses'**
  String get missedDosesSection;

  /// No description provided for @noMissedDoses.
  ///
  /// In en, this message translates to:
  /// **'No missed doses'**
  String get noMissedDoses;

  /// No description provided for @sendNudge.
  ///
  /// In en, this message translates to:
  /// **'Send Nudge'**
  String get sendNudge;

  /// No description provided for @nudgeRemindPatient.
  ///
  /// In en, this message translates to:
  /// **'Remind patient to take medication'**
  String get nudgeRemindPatient;

  /// No description provided for @nudgeSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Nudge sent successfully'**
  String get nudgeSentSuccess;

  /// No description provided for @nudgeSentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send nudge'**
  String get nudgeSentFailed;

  /// No description provided for @disconnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect?'**
  String get disconnectDialogTitle;

  /// No description provided for @disconnectDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to view this patient\'s medication information.'**
  String get disconnectDialogContent;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @gracePeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Grace Period'**
  String get gracePeriodTitle;

  /// No description provided for @gracePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace Period'**
  String get gracePeriodLabel;

  /// No description provided for @gracePeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Wait time before notifying family\nof missed medication'**
  String get gracePeriodDescription;

  /// No description provided for @gracePeriod10Min.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get gracePeriod10Min;

  /// No description provided for @notifyImmediatelyAfterMiss.
  ///
  /// In en, this message translates to:
  /// **'Notify immediately after missed dose'**
  String get notifyImmediatelyAfterMiss;

  /// No description provided for @gracePeriod20Min.
  ///
  /// In en, this message translates to:
  /// **'20 minutes'**
  String get gracePeriod20Min;

  /// No description provided for @allowSomeDelay.
  ///
  /// In en, this message translates to:
  /// **'Allow some time for delay'**
  String get allowSomeDelay;

  /// No description provided for @gracePeriod30Min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get gracePeriod30Min;

  /// No description provided for @defaultRecommended.
  ///
  /// In en, this message translates to:
  /// **'Default setting (Recommended)'**
  String get defaultRecommended;

  /// No description provided for @gracePeriod1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get gracePeriod1Hour;

  /// No description provided for @allowAdditionalTime.
  ///
  /// In en, this message translates to:
  /// **'Allow additional time'**
  String get allowAdditionalTime;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @recommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedBadge;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrTitle;

  /// No description provided for @positionQrInFrame.
  ///
  /// In en, this message translates to:
  /// **'Position QR code in the frame'**
  String get positionQrInFrame;

  /// No description provided for @qrWillScanAutomatically.
  ///
  /// In en, this message translates to:
  /// **'QR code will be scanned automatically'**
  String get qrWillScanAutomatically;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get searchCountry;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @phoneExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {example}'**
  String phoneExample(String example);

  /// No description provided for @registerWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Register with Google'**
  String get registerWithGoogle;

  /// No description provided for @orRegisterWith.
  ///
  /// In en, this message translates to:
  /// **'or register with'**
  String get orRegisterWith;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @emailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter email address'**
  String get emailEmpty;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhone;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number'**
  String get emailOrPhoneHint;

  /// No description provided for @emailOrPhoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter email or phone number'**
  String get emailOrPhoneEmpty;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number and we\'ll send you a code to reset your password'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Reset code sent successfully'**
  String get resetCodeSent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email/phone and your new password'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get newPasswordEmpty;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully! You can now login with your new password.'**
  String get passwordResetSuccess;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @selectSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Select Specialty'**
  String get selectSpecialty;

  /// No description provided for @specialtyGeneralPractice.
  ///
  /// In en, this message translates to:
  /// **'General Practice'**
  String get specialtyGeneralPractice;

  /// No description provided for @specialtyInternalMedicine.
  ///
  /// In en, this message translates to:
  /// **'Internal Medicine'**
  String get specialtyInternalMedicine;

  /// No description provided for @specialtyCardiology.
  ///
  /// In en, this message translates to:
  /// **'Cardiology'**
  String get specialtyCardiology;

  /// No description provided for @specialtyEndocrinology.
  ///
  /// In en, this message translates to:
  /// **'Endocrinology'**
  String get specialtyEndocrinology;

  /// No description provided for @specialtyDermatology.
  ///
  /// In en, this message translates to:
  /// **'Dermatology'**
  String get specialtyDermatology;

  /// No description provided for @specialtyPediatrics.
  ///
  /// In en, this message translates to:
  /// **'Pediatrics'**
  String get specialtyPediatrics;

  /// No description provided for @specialtyPsychiatry.
  ///
  /// In en, this message translates to:
  /// **'Psychiatry'**
  String get specialtyPsychiatry;

  /// No description provided for @specialtySurgery.
  ///
  /// In en, this message translates to:
  /// **'Surgery'**
  String get specialtySurgery;

  /// No description provided for @specialtyNeurology.
  ///
  /// In en, this message translates to:
  /// **'Neurology'**
  String get specialtyNeurology;

  /// No description provided for @specialtyOphthalmology.
  ///
  /// In en, this message translates to:
  /// **'Ophthalmology'**
  String get specialtyOphthalmology;

  /// No description provided for @specialtyOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get specialtyOther;

  /// No description provided for @hospitalClinicOptional.
  ///
  /// In en, this message translates to:
  /// **'(Optional - can fill later)'**
  String get hospitalClinicOptional;

  /// No description provided for @medicalLicenseOptional.
  ///
  /// In en, this message translates to:
  /// **'(Optional - can verify later)'**
  String get medicalLicenseOptional;

  /// No description provided for @licenseNotVerified.
  ///
  /// In en, this message translates to:
  /// **'License not yet verified'**
  String get licenseNotVerified;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @emailVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to your email'**
  String get emailVerificationSent;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get phoneOptional;

  /// No description provided for @singleMedicine.
  ///
  /// In en, this message translates to:
  /// **'Single Medicine'**
  String get singleMedicine;

  /// No description provided for @createBatchGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Batch Group'**
  String get createBatchGroup;

  /// No description provided for @batchName.
  ///
  /// In en, this message translates to:
  /// **'Batch Name'**
  String get batchName;

  /// No description provided for @batchNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., After Dinner'**
  String get batchNameHint;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @batchScheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time: {time}'**
  String batchScheduledTime(String time);

  /// No description provided for @reviewAndSave.
  ///
  /// In en, this message translates to:
  /// **'Review & Save'**
  String get reviewAndSave;

  /// No description provided for @batchCreated.
  ///
  /// In en, this message translates to:
  /// **'Batch group created successfully'**
  String get batchCreated;

  /// No description provided for @batchUpdated.
  ///
  /// In en, this message translates to:
  /// **'Batch group updated successfully'**
  String get batchUpdated;

  /// No description provided for @batchDeleted.
  ///
  /// In en, this message translates to:
  /// **'Batch group deleted'**
  String get batchDeleted;

  /// No description provided for @deleteBatch.
  ///
  /// In en, this message translates to:
  /// **'Delete Batch'**
  String get deleteBatch;

  /// No description provided for @noBatchGroups.
  ///
  /// In en, this message translates to:
  /// **'No batch groups yet'**
  String get noBatchGroups;

  /// No description provided for @batchGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Groups'**
  String get batchGroupsTitle;

  /// No description provided for @addToBatch.
  ///
  /// In en, this message translates to:
  /// **'Add to Batch'**
  String get addToBatch;

  /// No description provided for @removeFromBatch.
  ///
  /// In en, this message translates to:
  /// **'Remove from Batch'**
  String get removeFromBatch;

  /// No description provided for @batchMedicineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} medicine(s) in batch'**
  String batchMedicineCount(int count);

  /// No description provided for @deleteBatchConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this batch group?'**
  String get deleteBatchConfirmation;

  /// No description provided for @ocrPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Scanned Prescription'**
  String get ocrPreviewTitle;

  /// No description provided for @ocrPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Review and edit the extracted information before saving'**
  String get ocrPreviewDescription;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save'**
  String get confirmAndSave;

  /// No description provided for @editExtractedData.
  ///
  /// In en, this message translates to:
  /// **'Edit Extracted Data'**
  String get editExtractedData;

  /// No description provided for @extractedMedications.
  ///
  /// In en, this message translates to:
  /// **'Extracted Medications'**
  String get extractedMedications;

  /// No description provided for @noMedicationsExtracted.
  ///
  /// In en, this message translates to:
  /// **'No medications were extracted. Add medicines manually.'**
  String get noMedicationsExtracted;

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get addRow;

  /// No description provided for @chooseCreationMethod.
  ///
  /// In en, this message translates to:
  /// **'How would you like to add medication?'**
  String get chooseCreationMethod;

  /// No description provided for @singleMedicineDescription.
  ///
  /// In en, this message translates to:
  /// **'Add one medicine at a time with its own schedule'**
  String get singleMedicineDescription;

  /// No description provided for @batchGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Group multiple medicines taken at the same time'**
  String get batchGroupDescription;

  /// No description provided for @submitPrescription.
  ///
  /// In en, this message translates to:
  /// **'Submit Prescription'**
  String get submitPrescription;

  /// No description provided for @medicationTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationTableTitle;

  /// No description provided for @expandToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get expandToEdit;

  /// No description provided for @collapseRow.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseRow;

  /// No description provided for @removeMedicine.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMedicine;

  /// No description provided for @medicineNumber.
  ///
  /// In en, this message translates to:
  /// **'Medicine #{number}'**
  String medicineNumber(int number);

  /// No description provided for @prescriptionSummary.
  ///
  /// In en, this message translates to:
  /// **'Prescription Summary'**
  String get prescriptionSummary;

  /// No description provided for @batchReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Reminder: {name}'**
  String batchReminderTitle(String name);

  /// No description provided for @batchReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time to take: {medicines}'**
  String batchReminderBody(String medicines);

  /// No description provided for @timeToTakeMedicine.
  ///
  /// In en, this message translates to:
  /// **'Time to take {name}'**
  String timeToTakeMedicine(String name);
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
    'that was used.',
  );
}
