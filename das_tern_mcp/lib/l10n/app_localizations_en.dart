// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DasTern';

  @override
  String get appTagline => 'Medication Companion';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get orDivider => 'or';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get welcomeMessage => 'Your medication reminder companion';

  @override
  String get selectRoleTitle => 'I am...';

  @override
  String get selectRoleSubtitle => 'Select your role to get started';

  @override
  String get patientRole => 'Patient';

  @override
  String get patientRoleDescription =>
      'Track medication, set reminders, and manage prescriptions.';

  @override
  String get doctorRole => 'Doctor';

  @override
  String get doctorRoleDescription =>
      'Manage patients, create prescriptions, and monitor medication intake.';

  @override
  String get doctorRegistrationTitle => 'Doctor Registration';

  @override
  String get doctorRegistrationSubtitle =>
      'Fill in your information to create a doctor account';

  @override
  String get personalInfoSection => 'Personal Information';

  @override
  String get professionalInfoSection => 'Professional Information';

  @override
  String get accountSecuritySection => 'Account Security';

  @override
  String get accountVerificationInfo =>
      'Your account will be verified by our team.';

  @override
  String get step1PersonalInfo => 'Step 1 of 2 - Personal Information';

  @override
  String get step2AccountInfo => 'Step 2 of 2 - Account Information';

  @override
  String get lastName => 'Last Name';

  @override
  String get fillLastNameHint => 'Enter your last name';

  @override
  String get fillLastNameError => 'Please enter your last name';

  @override
  String get firstName => 'First Name';

  @override
  String get fillFirstNameHint => 'Enter your first name';

  @override
  String get fillFirstNameError => 'Please enter your first name';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get dateFormatPlaceholder => 'DD/MM/YYYY';

  @override
  String get pleaseSelectDateOfBirth => 'Please select date of birth';

  @override
  String get idCardNumber => 'ID Card Number';

  @override
  String get idCardNumberHint => 'Enter your ID card number';

  @override
  String get idCardNumberError => 'Please enter your ID card number';

  @override
  String get idCardOptional => '(Optional)';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => 'Enter your phone number';

  @override
  String get phoneNumberEmpty => 'Please enter phone number';

  @override
  String get phoneNumberInvalid => 'Invalid phone number';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get fullNameError => 'Please enter full name';

  @override
  String get hospitalClinic => 'Hospital / Clinic';

  @override
  String get hospitalClinicHint => 'Enter your hospital or clinic';

  @override
  String get hospitalClinicError => 'Please enter hospital';

  @override
  String get specialty => 'Specialty';

  @override
  String get specialtyHint => 'e.g. General Medicine, Cardiology';

  @override
  String get specialtyError => 'Please enter specialty';

  @override
  String get medicalLicense => 'Medical License Number';

  @override
  String get medicalLicenseHint => 'Enter your license number';

  @override
  String get medicalLicenseError => 'Please enter license number';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordEmpty => 'Please enter password';

  @override
  String get passwordTooShort => 'At least 6 characters required';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Enter your password again';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get continueButton => 'Continue';

  @override
  String get termsNotice =>
      'Please read the terms and conditions before using the app';

  @override
  String get termsRead => 'Already read';

  @override
  String get verifyCodeTitle => 'Verify Code';

  @override
  String get otpSentMessage => 'We sent a 4-digit code to';

  @override
  String get otpFillError => 'Please enter the 4-digit code';

  @override
  String get verifyButton => 'Verify';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend Code';

  @override
  String get hello => 'Hello';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get welcomeTitle => 'Welcome to DasTern';

  @override
  String get getStarted => 'Get Started';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get medications => 'Medications';

  @override
  String get analysis => 'Analysis';

  @override
  String get scan => 'Scan';

  @override
  String get family => 'Family';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get subscription => 'Subscription';

  @override
  String get unlockPremiumFeatures =>
      'Unlock premium features and get the most out of DasTern';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get todayMedications => 'Today\'s Medications';

  @override
  String get todayReminders => 'Today\'s Reminders';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get noRemindersToday => 'No reminders for today';

  @override
  String get medicineList => 'Medicine List';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get editMedicine => 'Edit Medicine';

  @override
  String get noMedicines => 'No medicines added yet';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get deleteMedication => 'Delete Medication';

  @override
  String get deleteMedicationMessage =>
      'Are you sure you want to delete this medication?';

  @override
  String get createMedication => 'Create Medication';

  @override
  String get noMedications => 'No medications added yet';

  @override
  String get medicationDeleted => 'Medication deleted successfully';

  @override
  String get medicationAdded => 'Medication added successfully';

  @override
  String get medicationUpdated => 'Medication updated successfully';

  @override
  String get medicationCreated => 'Medication created successfully';

  @override
  String get dosage => 'Dosage';

  @override
  String get dosageAmount => 'Dosage Amount';

  @override
  String get amount => 'Amount';

  @override
  String get unit => 'Unit';

  @override
  String get form => 'Form';

  @override
  String get frequency => 'Frequency';

  @override
  String get dose => 'dose';

  @override
  String get timesPerDay => 'times per day';

  @override
  String get tablet => 'Tablet';

  @override
  String get capsule => 'Capsule';

  @override
  String get liquid => 'Liquid';

  @override
  String get ml => 'ml';

  @override
  String get mg => 'mg';

  @override
  String get other => 'Other';

  @override
  String get regular => 'Regular';

  @override
  String get prn => 'As Needed (PRN)';

  @override
  String get instruction => 'Instruction';

  @override
  String get instructions => 'Instructions';

  @override
  String get prescribedBy => 'Prescribed By';

  @override
  String get enterMedicationName => 'Enter medication name';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterInstruction => 'Enter usage instructions';

  @override
  String get enterPrescriber => 'Enter prescriber name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get reminders => 'Reminders';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get manageReminders => 'Manage Reminders';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get deleteReminder => 'Delete Reminder';

  @override
  String get autoGenerateReminders => 'Auto-generate 3 daily reminders';

  @override
  String get remindersGenerated => 'Reminders generated successfully';

  @override
  String get reminderSet => 'Reminder set successfully';

  @override
  String get addTime => 'Add Time';

  @override
  String get noRemindersAdded =>
      'No reminder times added yet. Tap \'Add Time\' to set medication schedule.';

  @override
  String get addAtLeastOneReminder => 'Please add at least one reminder time';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get daytime => 'Daytime';

  @override
  String get timeOfDay => 'Time of Day';

  @override
  String get time => 'Time';

  @override
  String get days => 'Days';

  @override
  String get activeDays => 'Active Days';

  @override
  String get markAsTaken => 'Mark as Taken';

  @override
  String get markedAsTaken => 'Marked as taken';

  @override
  String get taken => 'Taken';

  @override
  String get takenAt => 'Taken at';

  @override
  String get skip => 'Skip';

  @override
  String get skipped => 'Skipped';

  @override
  String get missed => 'Missed';

  @override
  String get delayed => 'Delayed';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get scheduledFor => 'Scheduled for';

  @override
  String get upcomingReminders => 'Upcoming';

  @override
  String get completedReminders => 'Completed';

  @override
  String get history => 'History';

  @override
  String get intakeHistory => 'Intake History';

  @override
  String get adherenceRate => 'Adherence Rate';

  @override
  String get viewHistory => 'View History';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get all => 'All';

  @override
  String get viewAll => 'View All';

  @override
  String get patient => 'Patient';

  @override
  String get loginAsDoctor => 'Login as Doctor';

  @override
  String get selectDateOfBirth => 'Select date of birth';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get familyContact => 'Family Contact';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get address => 'Address (Optional)';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get pleaseEnterPhone => 'Please enter phone number';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get pleaseSelectBloodType => 'Please select blood type';

  @override
  String get pleaseEnterFamilyContact => 'Please enter family contact';

  @override
  String get loginError => 'Invalid phone number or password';

  @override
  String get registerSuccess => 'Registration successful!';

  @override
  String get enterPhoneHint => '012345678';

  @override
  String get enterPasswordHint => '••••••••';

  @override
  String get enterNameHint => 'Kimhour';

  @override
  String get enterFamilyContactHint => '098765432';

  @override
  String get enterWeightHint => '60.0';

  @override
  String get enterAddressHint => 'Street, District, Province';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get khmer => 'Khmer';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get about => 'About';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get done => 'Done';

  @override
  String get homeTab => 'Home';

  @override
  String get medicationsAnalysis => 'Medications';

  @override
  String get scanPrescriptionTab => 'Scan';

  @override
  String get familyFeatures => 'Family';

  @override
  String greetingName(String name) {
    return 'Hello $name!';
  }

  @override
  String get defaultPatientName => 'Patient';

  @override
  String get medicationTracker => 'Medication Tracker';

  @override
  String get beforeMeal => 'Before meal';

  @override
  String medicineCountLabel(int count) {
    return '$count medicine(s)';
  }

  @override
  String get progressMessage => 'Medicine intake progress';

  @override
  String dayProgress(int days) {
    return 'Day $days completed';
  }

  @override
  String get totalDuration => 'Total medication period 30 days';

  @override
  String get todaysTasks => 'Tasks (Today)';

  @override
  String get allCompleted => 'All completed!';

  @override
  String get noMoreMedicationsToday => 'No more medications for today';

  @override
  String get searchPrescription => 'Search prescriptions';

  @override
  String get medicationIntakeHistory => 'Medication\nintake history';

  @override
  String get healthVitals => 'Health Vitals';

  @override
  String get thresholds => 'Thresholds';

  @override
  String get emergencyLabel => 'Emergency';

  @override
  String get recordLabel => 'Record';

  @override
  String get onePill => '1 pill';

  @override
  String unresolvedAlerts(int count) {
    return '$count unresolved health alert(s)';
  }

  @override
  String get daysUnit => 'days';

  @override
  String get noActivePrescriptions => 'No active prescriptions';

  @override
  String get prescriptionsAppearHere =>
      'Your prescriptions will appear here\nonce added by your doctor.';

  @override
  String medicationCountLabel(int count) {
    return '$count medication(s)';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get oldPasswordHint => 'Enter old password';

  @override
  String get newPasswordHint => 'Enter your new password';

  @override
  String get passwordChangeComingSoon => 'Password change coming soon';

  @override
  String get preferences => 'Preferences';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myCaregivers => 'My Caregivers';

  @override
  String get patientsIMonitor => 'Patients I monitor';

  @override
  String get noConnections => 'No connections';

  @override
  String get connectWithFamily =>
      'Connect with family to\nmonitor medication intake';

  @override
  String get connectNow => 'Connect Now';

  @override
  String get viewAllConnections => 'View All Connections';

  @override
  String get activeStatus => 'Active';

  @override
  String get waitingStatus => 'Waiting';

  @override
  String get gracePeriodSettings => 'Grace Period Settings';

  @override
  String get unknown => 'Unknown';

  @override
  String get familyFunctionTitle => 'Family & Caregivers';

  @override
  String get familyIntroDescription =>
      'Connect with family members or caregivers to share your medication schedule.';

  @override
  String get familyBulletSender =>
      'Share your schedule with family to let them monitor your medication adherence';

  @override
  String get familyBulletReceiver =>
      'Scan a patient\'s QR code to start monitoring their medication intake';

  @override
  String get familyIntroFooter =>
      'Connections require patient approval and can be revoked at any time.';

  @override
  String get startUsing => 'Get Started';

  @override
  String get learnMore => 'Learn More';

  @override
  String get scanPrescriptionTitle => 'Scan Prescription';

  @override
  String get scanPrescriptionDescription =>
      'Use your camera to scan a prescription\nfrom your doctor.';

  @override
  String get openScanner => 'Open Scanner';

  @override
  String get scannerComingSoon => 'Scanner feature coming soon';

  @override
  String get scanFromCamera => 'Take Photo';

  @override
  String get scanFromGallery => 'Choose from Gallery';

  @override
  String get scanProcessing => 'Scanning prescription...';

  @override
  String get scanSuccess => 'Prescription scanned successfully!';

  @override
  String get scanFailed => 'Scan failed. Please try again.';

  @override
  String scanMedicationsFound(int count) {
    return '$count medications found';
  }

  @override
  String get doseHistoryAppearHere => 'Your dose history will appear here.';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get allFeaturesUnlocked => 'All features unlocked';

  @override
  String get upgradeToUnlock => 'Upgrade to unlock Premium features';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get myConnections => 'My Connections';

  @override
  String get logOut => 'Log Out';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String planNamePlan(String name) {
    return '$name Plan';
  }

  @override
  String pricePerMonth(String price) {
    return '\$$price/month';
  }

  @override
  String get bakongKHQR => 'Bakong (KHQR)';

  @override
  String get payWithCambodiaBank => 'Pay with any Cambodian banking app';

  @override
  String get scanQRWithBank =>
      'Scan QR code with ABA, ACLEDA, Wing, or any KHQR-supported bank';

  @override
  String get visaMastercard => 'Visa / Mastercard';

  @override
  String get internationalCard => 'International credit or debit card';

  @override
  String get internationalCardSupport =>
      'Support for Visa, Mastercard, and other international cards';

  @override
  String get bakongPaymentTitle => 'Bakong Payment';

  @override
  String get bakongKHQRPayment => 'Bakong KHQR Payment';

  @override
  String get nationalBankOfCambodia => 'National Bank of Cambodia';

  @override
  String get planSummary => 'Plan Summary';

  @override
  String get plan => 'Plan';

  @override
  String get price => 'Price';

  @override
  String get billingLabel => 'Billing';

  @override
  String get monthlyBilling => 'Monthly';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get howItWorks => 'How it Works';

  @override
  String get bakongStep1 => 'Click \"Confirm & Get QR Code\" below';

  @override
  String get bakongStep2 => 'Open your banking app (ABA, ACLEDA, Wing, etc.)';

  @override
  String get bakongStep3 => 'Scan the QR code displayed on screen';

  @override
  String get bakongStep4 => 'Confirm payment in your banking app';

  @override
  String get bakongStep5 => 'Your plan will be upgraded automatically';

  @override
  String get paymentSecureNotice =>
      'Your payment is processed securely through the Bakong system by the National Bank of Cambodia.';

  @override
  String get confirmAndGetQR => 'Confirm & Get QR Code';

  @override
  String get scanToPay => 'Scan to Pay';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get paymentExpired => 'Payment Expired';

  @override
  String get waitingForPayment => 'Waiting for Payment';

  @override
  String get waitingForPaymentEllipsis => 'Waiting for payment...';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get howToPay => 'How to Pay';

  @override
  String get howToPayStep1 => '1. Open your banking app';

  @override
  String get howToPayStep2 => '2. Select \"Scan QR\" or \"KHQR\"';

  @override
  String get howToPayStep3 => '3. Scan the QR code above';

  @override
  String get howToPayStep4 => '4. Confirm the amount and pay';

  @override
  String get howToPayStep5 => '5. Payment will be verified automatically';

  @override
  String get payWithBankingApp => 'Pay with Banking App';

  @override
  String get selectYourBank => 'Select Your Bank';

  @override
  String get openInBankingApp => 'Open in Banking App';

  @override
  String get orOpenDirectly => 'Or tap to open your banking app directly:';

  @override
  String get noBankingAppInstalled =>
      'Could not open banking app. Please scan the QR code instead.';

  @override
  String get bankNotInstalled =>
      'App not installed. Please scan the QR code instead.';

  @override
  String get supportedByAllKHQR => 'Supported by all KHQR banks';

  @override
  String get cancelPayment => 'Cancel Payment?';

  @override
  String get cancelPaymentMessage =>
      'Are you sure you want to cancel? Your payment will not be processed.';

  @override
  String get keepWaiting => 'Keep Waiting';

  @override
  String get subscriptionUpgraded => 'Your subscription has been upgraded';

  @override
  String get allPremiumFeaturesUnlocked =>
      'All premium features are now unlocked';

  @override
  String get unlimitedPrescriptions => '∞ Prescriptions';

  @override
  String get storageAmount => '20 GB';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get upgradePlan => 'Upgrade Plan';

  @override
  String get choosePlan => 'Choose a Plan';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get currentLabel => 'Current';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get featureComparison => 'Feature Comparison';

  @override
  String get prescriptionsFeature => 'Prescriptions';

  @override
  String get medicinesFeature => 'Medicines';

  @override
  String get familyLinksFeature => 'Family Links';

  @override
  String get storageFeature => 'Storage';

  @override
  String get prioritySupportFeature => 'Priority Support';

  @override
  String get familyPlanFeature => 'Family Plan';

  @override
  String get premiumTrialActive => 'Premium Trial Active';

  @override
  String get dayRemaining => 'day remaining';

  @override
  String get daysRemaining => 'days remaining';

  @override
  String get expiresToday => 'Expires today';

  @override
  String get enjoyUnlimitedFeatures => 'Enjoy unlimited OCR & family features';

  @override
  String get claimFreeTrial => 'Claim 1-Month Free Trial';

  @override
  String get trialAlreadyClaimed => 'Trial already claimed';

  @override
  String get claimingTrial => 'Activating trial...';

  @override
  String get trialClaimedSuccess =>
      'Free trial activated! Enjoy Premium features for 1 month.';

  @override
  String get trialClaimFailed => 'Failed to activate trial. Please try again.';

  @override
  String get premiumTrial => 'Premium Trial';

  @override
  String get topFeatures => 'Top Features';

  @override
  String get cancelAnytime => 'Cancel anytime';

  @override
  String get trialReminderNote =>
      'We\'ll remind you 3 days before your trial ends';

  @override
  String get expandedOcrFeature => 'Unlimited OCR prescription scanning';

  @override
  String get familyConnectionsFeature => 'Connect up to 5 family members';

  @override
  String get expandedStorageFeature =>
      '20 GB cloud storage for medical records';

  @override
  String get trialPeriod => 'Trial Period';

  @override
  String get oneMonthFree => '1 month free';

  @override
  String get promotion => 'Promotion';

  @override
  String get hundredPercentOff => '100% off for 1 month';

  @override
  String get afterTrial => 'After Trial';

  @override
  String get dueToday => 'Due today';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get ocrPremiumMessage =>
      'OCR scanning is a Premium feature. Upgrade to Premium to unlock:';

  @override
  String get unlimitedOcrScanning => 'Unlimited OCR scanning';

  @override
  String get connectFamilyMembers => 'Connect up to 5 family members';

  @override
  String get twentyGBStorage => '20 GB storage';

  @override
  String get prioritySupport => 'Priority support';

  @override
  String get freeTrialOffer => '1-month free trial for new users!';

  @override
  String get claimYourFreeTrial => 'Claim Your Free Trial';

  @override
  String get getOneMonthFreePremiumAccess => 'Get 1 month free premium access';

  @override
  String get claimTrial => 'Claim Trial';

  @override
  String trialDaysRemainingBanner(int days) {
    return 'You have $days days remaining';
  }

  @override
  String get yourTrialPeriod => 'Your Trial Period';

  @override
  String get trialExpiresOn => 'Trial expires on';

  @override
  String get daysLeft => 'days left';

  @override
  String get dayLeft => 'day left';

  @override
  String get enjoyingPremium => 'You are enjoying Premium features';

  @override
  String get afterTrialEnds => 'After trial ends';

  @override
  String get autoRevertToFree =>
      'Your plan will automatically revert to Freemium (Free plan)';

  @override
  String get keepPremiumFeatures => 'Want to keep Premium features?';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get onlyPerMonth => 'Only \$0.50/month or \$1 for 3 months';

  @override
  String get whatYouGet => 'What you\'re enjoying now';

  @override
  String get continuePremium => 'Continue with Premium';

  @override
  String get addAtLeastOneMedicine => 'Add at least one medicine';

  @override
  String get selfPrescribed => 'Self-prescribed';

  @override
  String get medicineAddedSuccessfully => 'Medicine added successfully';

  @override
  String get labelPurpose => 'Label / Purpose';

  @override
  String get labelPurposeHint => 'e.g. Daily vitamins';

  @override
  String get addedMedicines => 'Added Medicines';

  @override
  String saveWithCount(int count) {
    return 'Save ($count medicine(s))';
  }

  @override
  String get recordVital => 'Record Vital';

  @override
  String get selectVitalType => 'Select Vital Type';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get enterValue => 'Enter value';

  @override
  String get measuredAt => 'Measured at';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get vitalRecordedSuccess => 'Vital recorded successfully';

  @override
  String get failedToRecordVital => 'Failed to record vital';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String daysCount(String count) {
    return '$count days';
  }

  @override
  String get alertThresholds => 'Alert Thresholds';

  @override
  String get usingDefaults => 'Using defaults';

  @override
  String minLabel(String unit) {
    return 'Min ($unit)';
  }

  @override
  String maxLabel(String unit) {
    return 'Max ($unit)';
  }

  @override
  String get minDiastolic => 'Min Diastolic';

  @override
  String get maxDiastolic => 'Max Diastolic';

  @override
  String get confirmEmergency => 'Confirm Emergency';

  @override
  String get confirmEmergencyMessage =>
      'This will send an emergency alert to all your connected caregivers and doctors. Are you sure?';

  @override
  String get emergencyAlertSent => 'Emergency Alert Sent';

  @override
  String get caregiversNotified =>
      'All connected caregivers and doctors have been notified.';

  @override
  String get emergencyAlert => 'Emergency Alert';

  @override
  String get emergencyAlertDescription =>
      'Tap the button below to alert all your connected caregivers and doctors.';

  @override
  String get messageOptional => 'Message (optional)';

  @override
  String get describeSituation => 'Describe your situation...';

  @override
  String get emergencyAlertTriggered => 'Emergency alert triggered';

  @override
  String get doctorPatientsTab => 'Patients';

  @override
  String get doctorPrescriptionsTab => 'Prescriptions';

  @override
  String get doctorPrescriptionHistoryTab => 'History';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get totalPatients => 'Total Patients';

  @override
  String get needAttention => 'Need Attention';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get todayAlerts => 'Today Alerts';

  @override
  String get criticalAlerts => 'Critical Alerts';

  @override
  String consecutiveMissedDoses(int count) {
    return '$count consecutive missed doses';
  }

  @override
  String get pendingConnectionRequests => 'Pending Connection Requests';

  @override
  String get connectionRequest => 'Connection request';

  @override
  String get newPrescription => 'New Prescription';

  @override
  String get findPatient => 'Find Patient';

  @override
  String get personUnit => 'person(s)';

  @override
  String get statisticsChart => 'Statistics Chart';

  @override
  String get receivedMeds => 'Received';

  @override
  String get missedMeds => 'Missed';

  @override
  String get dayFilter => 'Day';

  @override
  String get monthFilter => 'Month';

  @override
  String get alertsLabel => 'Alerts';

  @override
  String get missedTimesLabel => 'times';

  @override
  String get noAlerts => 'No alerts at this time';

  @override
  String get noReceivingPatientsHint =>
      'No patients are currently receiving medication';

  @override
  String get noPendingPatientsHint =>
      'All patients are on track — no pending medication';

  @override
  String get patientsInTreatment => 'Patients Received Medication';

  @override
  String get patientsPendingMeds => 'Patients Pending Medication';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get myPatients => 'My Patients';

  @override
  String get searchPatients => 'Search patients...';

  @override
  String get adherenceGood => 'Good';

  @override
  String get adherenceModerate => 'Moderate';

  @override
  String get adherencePoor => 'Poor';

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String get tryDifferentSearch => 'Try a different search.';

  @override
  String get connectedPatientsAppearHere =>
      'Connected patients will appear here.';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get noPrescriptions => 'No prescriptions';

  @override
  String get createPrescription => 'Create Prescription';

  @override
  String get prescriptionHistory => 'Prescription History';

  @override
  String get noPrescriptionHistory => 'No prescription history';

  @override
  String get prescriptionsCreatedAppearHere =>
      'Your created prescriptions\nwill appear here.';

  @override
  String get overview => 'Overview';

  @override
  String get adherence => 'Adherence';

  @override
  String get vitals => 'Vitals';

  @override
  String get notes => 'Notes';

  @override
  String get failedToLoadPatientDetails => 'Failed to load patient details';

  @override
  String ageLabel(String age, String gender) {
    return 'Age: $age · $gender';
  }

  @override
  String get late => 'Late';

  @override
  String activePrescriptionsCount(int count) {
    return 'Active Prescriptions ($count)';
  }

  @override
  String get prescription => 'Prescription';

  @override
  String statusMedicines(String status, int count) {
    return '$status · $count medicines';
  }

  @override
  String get noAdherenceData => 'No adherence data available';

  @override
  String get dailyAdherenceLast30 => 'Daily Adherence (Last 30 Days)';

  @override
  String get dailyBreakdown => 'Daily Breakdown';

  @override
  String get addNoteHint => 'Add a note...';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get editNote => 'Edit Note';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get deleteNoteConfirmation =>
      'Are you sure you want to delete this note?';

  @override
  String get noVitalReadings => 'No vital readings recorded';

  @override
  String get latestReadings => 'Latest Readings';

  @override
  String historyCount(int count) {
    return 'History ($count)';
  }

  @override
  String get selectPatient => 'Select Patient';

  @override
  String get diagnosis => 'Diagnosis';

  @override
  String get medicines => 'Medicines';

  @override
  String get reviewStep => 'Review';

  @override
  String get noConnectedPatients => 'No connected patients found.';

  @override
  String get symptomsLabel => 'Symptoms';

  @override
  String get symptomsRequired => 'Symptoms *';

  @override
  String get diagnosisRequired => 'Diagnosis *';

  @override
  String get clinicalNote => 'Clinical Note';

  @override
  String get followUpLabel => 'Follow-up';

  @override
  String get setFollowUpDate => 'Set follow-up date';

  @override
  String followUpDateValue(String date) {
    return 'Follow-up: $date';
  }

  @override
  String get prescriptionCreated => 'Prescription created';

  @override
  String get prescriptionDetails => 'Prescription Details';

  @override
  String get notFound => 'Not found';

  @override
  String get licenseNumber => 'License #';

  @override
  String get versionLabel => 'Version';

  @override
  String get timing => 'Timing';

  @override
  String get durationDays => 'Duration';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get pauseButton => 'Pause';

  @override
  String get resumeButton => 'Resume';

  @override
  String get medicineNameRequired => 'Medicine Name *';

  @override
  String get medicineNameHintExample => 'e.g. Paracetamol';

  @override
  String get medicineNameKhmer => 'Medicine Name (Khmer)';

  @override
  String get typeLabel => 'Type';

  @override
  String get frequencyRequired => 'Frequency *';

  @override
  String get frequencyHintExample => 'e.g. 2 times/day';

  @override
  String get durationDaysLabel => 'Duration (days)';

  @override
  String get schedule => 'Schedule';

  @override
  String get additionalNote => 'Additional Note';

  @override
  String get saveMedicine => 'Save Medicine';

  @override
  String get required => 'Required';

  @override
  String get connectFamilyTitle => 'Connect Family';

  @override
  String get shareMedicationWithFamily =>
      'Share your medication information with family\nso they can help monitor';

  @override
  String get shareQrCode => 'Share QR Code';

  @override
  String get generateCodeForFamily => 'Generate code for family to scan';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get scanCodeFromPatient => 'Scan code from patient to connect';

  @override
  String get enterCodeManually => 'Enter Code Manually';

  @override
  String get enterEightDigitConnectionCode => 'Enter 8-digit connection code';

  @override
  String get codeValidFor24Hours => 'Code valid for 24 hours';

  @override
  String get enterCodeTitle => 'Enter Code';

  @override
  String get enterConnectionCode => 'Enter Connection Code';

  @override
  String get enterEightDigitFromPatient =>
      'Please enter the 8-digit code from the patient';

  @override
  String get codeHintPlaceholder => 'XXXXXXXX';

  @override
  String get pleaseEnterCode => 'Please enter a code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get scanQrInstead => 'Scan QR code instead';

  @override
  String get connectionCodeTitle => 'Connection Code';

  @override
  String get failedToGenerateToken => 'Failed to generate token';

  @override
  String get tokenExpired => 'Expired';

  @override
  String timeRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String get cannotGenerateCode => 'Cannot generate code';

  @override
  String get orUseCode => 'Or use code';

  @override
  String get instructionStep1Family => 'Open app on family member\'s phone';

  @override
  String get instructionStep2Family => 'Tap \"Scan QR Code\" or \"Enter Code\"';

  @override
  String get instructionStep3Family => 'Scan this QR code or enter the code';

  @override
  String get shareCodeButton => 'Share Code';

  @override
  String shareCodeMessage(String token) {
    return 'DasTern connection code: $token';
  }

  @override
  String get generateNewCode => 'Generate New Code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get connectionTitle => 'Connection';

  @override
  String get invalidToken => 'Invalid token';

  @override
  String get tokenInvalidOrExpired => 'Token is invalid or expired';

  @override
  String get connectionSuccess => 'Connection successful!';

  @override
  String get failedToConnect => 'Failed to connect';

  @override
  String get codeInvalid => 'Invalid Code';

  @override
  String get codeValidTitle => 'Code Valid!';

  @override
  String get connectionRequiresApproval =>
      'This connection will require patient approval';

  @override
  String get expiresLabel => 'Expires';

  @override
  String get hoursUnit => 'hours';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get connectionHistory => 'Connection History';

  @override
  String get filterAccepted => 'Accepted';

  @override
  String get filterRevoked => 'Revoked';

  @override
  String get noHistoryFound => 'No history';

  @override
  String get connectionLabel => 'Connection';

  @override
  String get myFamily => 'My Family';

  @override
  String get caregiversTab => 'Caregivers';

  @override
  String get patientsTab => 'Patients';

  @override
  String get newConnection => 'New Connection';

  @override
  String get noCaregiversYet => 'No caregivers yet';

  @override
  String get shareQrToAllowFamily =>
      'Share QR code to allow family members\nto monitor medication adherence';

  @override
  String get notMonitoringPatients => 'Not monitoring any patients';

  @override
  String get scanQrToStartMonitoring =>
      'Scan QR code from patient to start\nmonitoring medication adherence';

  @override
  String get caregiverLabel => 'Caregiver';

  @override
  String get statusRevoked => 'Revoked';

  @override
  String get accessLevelTitle => 'Access Level';

  @override
  String get selectAccessLevel => 'Select Access Level';

  @override
  String get accessLevelChangeableLater => 'You can change this level later';

  @override
  String get viewOnly => 'View Only';

  @override
  String get viewOnlyDescription =>
      'Caregiver can only view medication schedules';

  @override
  String get viewAndRemind => 'View + Remind';

  @override
  String get viewAndRemindDescription =>
      'Caregiver can view and send nudge reminders';

  @override
  String get viewAndManage => 'View + Manage';

  @override
  String get viewAndManageDescription =>
      'Caregiver can view, remind and edit schedules';

  @override
  String get connectionNotFound => 'Connection not found';

  @override
  String get disconnectConnection => 'Disconnect Connection';

  @override
  String get todayMedicationSchedule => 'Today\'s Medication Schedule';

  @override
  String get noMedicationData => 'No medication data';

  @override
  String get connectionConnected => 'Connected';

  @override
  String get missedDosesSection => 'Missed Doses';

  @override
  String get noMissedDoses => 'No missed doses';

  @override
  String get sendNudge => 'Send Nudge';

  @override
  String get nudgeRemindPatient => 'Remind patient to take medication';

  @override
  String get nudgeSentSuccess => 'Nudge sent successfully';

  @override
  String get nudgeSentFailed => 'Failed to send nudge';

  @override
  String get disconnectDialogTitle => 'Disconnect?';

  @override
  String get disconnectDialogContent =>
      'You will no longer be able to view this patient\'s medication information.';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get gracePeriodTitle => 'Grace Period';

  @override
  String get gracePeriodLabel => 'Grace Period';

  @override
  String get gracePeriodDescription =>
      'Wait time before notifying family\nof missed medication';

  @override
  String get gracePeriod10Min => '10 minutes';

  @override
  String get notifyImmediatelyAfterMiss =>
      'Notify immediately after missed dose';

  @override
  String get gracePeriod20Min => '20 minutes';

  @override
  String get allowSomeDelay => 'Allow some time for delay';

  @override
  String get gracePeriod30Min => '30 minutes';

  @override
  String get defaultRecommended => 'Default setting (Recommended)';

  @override
  String get gracePeriod1Hour => '1 hour';

  @override
  String get allowAdditionalTime => 'Allow additional time';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get recommendedBadge => 'Recommended';

  @override
  String get scanQrTitle => 'Scan QR Code';

  @override
  String get positionQrInFrame => 'Position QR code in the frame';

  @override
  String get qrWillScanAutomatically => 'QR code will be scanned automatically';

  @override
  String get searchCountry => 'Search country...';

  @override
  String get selectCountry => 'Select Country';

  @override
  String phoneExample(String example) {
    return 'e.g. $example';
  }

  @override
  String get registerWithGoogle => 'Register with Google';

  @override
  String get orRegisterWith => 'or register with';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get emailEmpty => 'Please enter email address';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get emailOrPhone => 'Email or Phone Number';

  @override
  String get emailOrPhoneHint => 'Enter your email or phone number';

  @override
  String get emailOrPhoneEmpty => 'Please enter email or phone number';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email or phone number and we\'ll send you a code to reset your password';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get resetCodeSent => 'Reset code sent successfully';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the code sent to your email/phone and your new password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordEmpty => 'Please enter new password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordHint => 'Re-enter your new password';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully! You can now login with your new password.';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get selectSpecialty => 'Select Specialty';

  @override
  String get specialtyGeneralPractice => 'General Practice';

  @override
  String get specialtyInternalMedicine => 'Internal Medicine';

  @override
  String get specialtyCardiology => 'Cardiology';

  @override
  String get specialtyEndocrinology => 'Endocrinology';

  @override
  String get specialtyDermatology => 'Dermatology';

  @override
  String get specialtyPediatrics => 'Pediatrics';

  @override
  String get specialtyPsychiatry => 'Psychiatry';

  @override
  String get specialtySurgery => 'Surgery';

  @override
  String get specialtyNeurology => 'Neurology';

  @override
  String get specialtyOphthalmology => 'Ophthalmology';

  @override
  String get specialtyOther => 'Other';

  @override
  String get hospitalClinicOptional => '(Optional - can fill later)';

  @override
  String get medicalLicenseOptional => '(Optional - can verify later)';

  @override
  String get licenseNotVerified => 'License not yet verified';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get emailVerificationSent =>
      'A verification code has been sent to your email';

  @override
  String get phoneOptional => '(Optional)';

  @override
  String get singleMedicine => 'Single Medicine';

  @override
  String get createBatchGroup => 'Create Batch Group';

  @override
  String get batchName => 'Batch Name';

  @override
  String get batchNameHint => 'e.g., After Dinner';

  @override
  String get selectTime => 'Select Time';

  @override
  String batchScheduledTime(String time) {
    return 'Scheduled Time: $time';
  }

  @override
  String get reviewAndSave => 'Review & Save';

  @override
  String get batchCreated => 'Batch group created successfully';

  @override
  String get batchUpdated => 'Batch group updated successfully';

  @override
  String get batchDeleted => 'Batch group deleted';

  @override
  String get deleteBatch => 'Delete Batch';

  @override
  String get noBatchGroups => 'No batch groups yet';

  @override
  String get batchGroupsTitle => 'Batch Groups';

  @override
  String get addToBatch => 'Add to Batch';

  @override
  String get removeFromBatch => 'Remove from Batch';

  @override
  String batchMedicineCount(int count) {
    return '$count medicine(s) in batch';
  }

  @override
  String get deleteBatchConfirmation =>
      'Are you sure you want to delete this batch group?';

  @override
  String get ocrPreviewTitle => 'Review Scanned Prescription';

  @override
  String get ocrPreviewDescription =>
      'Review and edit the extracted information before saving';

  @override
  String get confirmAndSave => 'Confirm & Save';

  @override
  String get editExtractedData => 'Edit Extracted Data';

  @override
  String get extractedMedications => 'Extracted Medications';

  @override
  String get noMedicationsExtracted =>
      'No medications were extracted. Add medicines manually.';

  @override
  String get addRow => 'Add Row';

  @override
  String get chooseCreationMethod => 'How would you like to add medication?';

  @override
  String get singleMedicineDescription =>
      'Add one medicine at a time with its own schedule';

  @override
  String get batchGroupDescription =>
      'Group multiple medicines taken at the same time';

  @override
  String get submitPrescription => 'Submit Prescription';

  @override
  String get medicationTableTitle => 'Medications';

  @override
  String get expandToEdit => 'Tap to edit';

  @override
  String get collapseRow => 'Collapse';

  @override
  String get removeMedicine => 'Remove';

  @override
  String medicineNumber(int number) {
    return 'Medicine #$number';
  }

  @override
  String get prescriptionSummary => 'Prescription Summary';

  @override
  String batchReminderTitle(String name) {
    return 'Batch Reminder: $name';
  }

  @override
  String batchReminderBody(String medicines) {
    return 'Time to take: $medicines';
  }

  @override
  String timeToTakeMedicine(String name) {
    return 'Time to take $name';
  }

  @override
  String get rowNumberColumn => '#';

  @override
  String get medicineNameColumn => 'Medicine';

  @override
  String get morningColumn => 'Morning';

  @override
  String get daytimeColumn => 'Daytime';

  @override
  String get nightColumn => 'Night';

  @override
  String get afterMeal => 'After meal';

  @override
  String get addMedicineRow => 'Add medicine row';

  @override
  String get createPrescriptionFab => 'Create Prescription';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get currentPrescriptions => 'Current Prescriptions';

  @override
  String get missedMedicationCount => 'Missed Medications';

  @override
  String get profileSection => 'Profile';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get aboutUs => 'About Us';

  @override
  String get personalAccount => 'Personal Account';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get medicationReminders => 'Medication Reminders';

  @override
  String get missedDoseAlerts => 'Missed Dose Alerts';

  @override
  String get connectionAlerts => 'Connection Alerts';

  @override
  String get emergencyNotifications => 'Emergency Notifications';

  @override
  String get appVersion => 'App Version';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get manageSubscriptions => 'Manage Subscriptions';

  @override
  String get restoreSubscription => 'Restore Subscription';

  @override
  String get rateApp => 'Rate App';

  @override
  String get support => 'Support';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String adherencePercentage(String percentage) {
    return '$percentage%';
  }

  @override
  String get connectNewPatient => 'Connect New Patient';

  @override
  String get enterPhoneOrEmail => 'Enter phone number or email';

  @override
  String get noPatientFound => 'No patient found';

  @override
  String get connectionRequestSent => 'Connection request sent';

  @override
  String get connectionRequestFailed => 'Failed to send connection request';

  @override
  String get sendConnectionRequest => 'Send Connection Request';

  @override
  String get doctorStep1PersonalInfo => 'Step 1 of 2 - Personal Info';

  @override
  String get doctorStep2ProfessionalInfo => 'Step 2 of 2 - Professional Info';

  @override
  String get welcomeScreenSubtitle => 'Your trusted medication companion';

  @override
  String get emergencyAccess => 'Emergency Access';

  @override
  String get connectionApproved => 'Connection Approved';

  @override
  String get connectionRejected => 'Connection Rejected';

  @override
  String get removeNotification => 'Remove Notification';

  @override
  String get removeNotificationConfirm =>
      'Are you sure you want to remove this notification?';

  @override
  String get remove => 'Remove';

  @override
  String shareQrAndCodeMessage(String token) {
    return 'DasTern QR & Connection Code: $token';
  }

  @override
  String get rejectConnection => 'Reject';

  @override
  String get approveConnection => 'Approve';

  @override
  String get ocrOutpatient => 'Outpatient';

  @override
  String get ocrInpatient => 'Inpatient';

  @override
  String get ocrFacilityHospital => 'Hospital';

  @override
  String get ocrFacilityClinic => 'Clinic';

  @override
  String get ocrNeedsReviewYes => 'Needs Review';

  @override
  String get ocrAiEnhanced => 'AI Enhanced';

  @override
  String get ocrAiUnavailable => 'AI Unavailable';

  @override
  String get bankAmountPreFilled => 'Amount pre-filled by bank';

  @override
  String ocrConfidencePercent(String percent) {
    return '$percent% confidence';
  }

  @override
  String get ocrNotAvailable => 'N/A';

  @override
  String get ocrScanInfoSection => 'Scan Information';

  @override
  String get ocrPrescriberSection => 'Prescriber';

  @override
  String get ocrPrescriberName => 'Prescriber Name';

  @override
  String get ocrFacilitySection => 'Facility';

  @override
  String get ocrFacilityName => 'Facility Name';

  @override
  String get ocrFacilityType => 'Facility Type';

  @override
  String get ocrValidated => 'Validated';

  @override
  String get ocrMetadataSection => 'OCR Metadata';

  @override
  String get ocrConfidenceScore => 'Confidence Score';

  @override
  String get ocrEngine => 'OCR Engine';

  @override
  String get ocrProcessingTime => 'Processing Time';

  @override
  String ocrMilliseconds(String ms) {
    return '${ms}ms';
  }

  @override
  String get ocrPrescriptionType => 'Prescription Type';

  @override
  String get ocrLanguagesDetected => 'Languages Detected';

  @override
  String get ocrValidationStatus => 'Validation Status';

  @override
  String get rejectPrescription => 'Reject Prescription';

  @override
  String get prescriptionRejected => 'Prescription rejected';

  @override
  String get prescriptionConfirmed => 'Prescription confirmed';

  @override
  String get confirmPrescription => 'Confirm Prescription';

  @override
  String get pendingPrescriptions => 'Pending Prescriptions';

  @override
  String prescriptionFromDoctor(String name) {
    return 'From Dr. $name';
  }

  @override
  String get missedDoseBanner => 'You have missed doses today';

  @override
  String get appearance => 'Appearance';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get rateAppSubtitle => 'Share your feedback on the App Store';

  @override
  String get contactSupportSubtitle => 'Get help from our support team';

  @override
  String get termsOfServiceSubtitle => 'Read our terms and conditions';

  @override
  String get privacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get tosLastUpdated => 'Last updated: March 1, 2026';

  @override
  String get tosContactFooter => 'Questions? Contact us at support@dastern.com';

  @override
  String get tosSection1Title => 'Acceptance of Terms';

  @override
  String get tosSection1Body =>
      'By accessing or using DasTern, you agree to be bound by these Terms of Service. If you do not agree, please do not use the application.';

  @override
  String get tosSection2Title => 'Description of Service';

  @override
  String get tosSection2Body =>
      'DasTern provides medication management, health tracking, and telemedicine features. The app is not a substitute for professional medical advice, diagnosis, or treatment.';

  @override
  String get tosSection3Title => 'User Accounts';

  @override
  String get tosSection3Body =>
      'You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information and to update it as necessary.';

  @override
  String get tosSection4Title => 'Subscription & Payments';

  @override
  String get tosSection4Body =>
      'Some features require a paid subscription. Prices are displayed before purchase. You may cancel at any time; access continues until the end of the billing period.';

  @override
  String get tosSection5Title => 'Intellectual Property';

  @override
  String get tosSection5Body =>
      'All content, trademarks, and software in DasTern are owned by or licensed to us. You may not copy, modify, or distribute any part without written permission.';

  @override
  String get tosSection6Title => 'Limitation of Liability';

  @override
  String get tosSection6Body =>
      'DasTern is provided as is. We are not liable for any indirect, incidental, or consequential damages arising from your use of the service.';

  @override
  String get tosSection7Title => 'Changes to Terms';

  @override
  String get tosSection7Body =>
      'We reserve the right to modify these terms at any time. Continued use after changes constitutes acceptance of the new terms.';

  @override
  String get ppLastUpdated => 'Last updated: March 1, 2026';

  @override
  String get ppHighlightBanner =>
      'Your health data is encrypted end-to-end and never shared without consent.';

  @override
  String get ppContactFooter => 'Questions? Contact privacy@dastern.com';

  @override
  String get ppSection1Title => 'Information We Collect';

  @override
  String get ppSection1Body =>
      'We collect personal information you provide (name, email, health data) and automatically gathered data (device info, usage patterns) to deliver and improve our services.';

  @override
  String get ppSection2Title => 'Health Data';

  @override
  String get ppSection2Body =>
      'Medication records, vital signs, and health notes are stored securely. We never sell health data. Access is limited to you, your care team (with your consent), and authorized staff for service delivery.';

  @override
  String get ppSection3Title => 'Data Security';

  @override
  String get ppSection3Body =>
      'We use industry-standard encryption (AES-256) for data at rest and TLS 1.3 for data in transit. Access is controlled with role-based permissions and regular security audits.';

  @override
  String get ppSection4Title => 'Sharing & Disclosure';

  @override
  String get ppSection4Body =>
      'We do not sell your data. We may share information with healthcare providers you authorize, service partners under strict agreements, or when required by law.';

  @override
  String get ppSection5Title => 'Cookies & Analytics';

  @override
  String get ppSection5Body =>
      'We use minimal analytics to understand app usage and improve features. No third-party advertising trackers are used in DasTern.';

  @override
  String get ppSection6Title => 'Your Rights';

  @override
  String get ppSection6Body =>
      'You can access, correct, export, or delete your personal data at any time from your profile settings. You may also withdraw consent for optional data processing.';

  @override
  String get ppSection7Title => 'Policy Changes';

  @override
  String get ppSection7Body =>
      'We will notify you of significant changes via in-app notification or email. Continued use after changes constitutes acceptance.';

  @override
  String get csHowCanWeHelp => 'How can we help?';

  @override
  String get csChooseOption => 'Choose an option below to get in touch';

  @override
  String get csEmailUs => 'Email Us';

  @override
  String get csSend => 'Send';

  @override
  String get csCallUs => 'Call Us';

  @override
  String get csCall => 'Call';

  @override
  String get csOfficeHours => 'Office Hours';

  @override
  String get csOfficeHoursValue => 'Mon – Fri, 8 AM – 6 PM (ICT)';

  @override
  String get csResponseTime => 'We usually respond within 24 hours.';

  @override
  String get termsSubtitle => 'Read our terms & conditions';

  @override
  String get privacySubtitle => 'How we protect your data';

  @override
  String get helpImprove => 'Help us improve DasTern';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinutes(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeAgoDays(int days) {
    return '${days}d ago';
  }

  @override
  String get createPrescriptionManual => 'Create Prescription Manually';

  @override
  String get createPrescriptionManualDesc =>
      'Build a prescription step-by-step with full control';

  @override
  String get scanPrescriptionOption => 'Scan Prescription';

  @override
  String get scanPrescriptionOptionDesc =>
      'Use camera OCR to extract medicines from paper prescriptions';

  @override
  String get quickAddMedicine => 'Quick Add Medicine';

  @override
  String get quickAddMedicineDesc =>
      'Add a single medicine quickly with basic schedule';

  @override
  String get activityReport => 'Activity Report';

  @override
  String get adherenceSummary => 'Adherence Summary';

  @override
  String get weeklyAdherence => 'Weekly Adherence';

  @override
  String get monthlyAdherence => 'Monthly Adherence';

  @override
  String get totalDoses => 'Total Doses';

  @override
  String get doseHistory => 'Dose History';

  @override
  String get onTime => 'On Time';

  @override
  String get wizardStepPrescription => 'Prescription';

  @override
  String get wizardStepMedicines => 'Medicines';

  @override
  String get wizardStepReview => 'Review';

  @override
  String get prescriptionName => 'Prescription Name';

  @override
  String get prescriptionNameHint => 'e.g. Blood pressure treatment';

  @override
  String get doctorNameOptional => 'Doctor Name (Optional)';

  @override
  String get doctorNameHint => 'e.g. Dr. Chan Dara';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String medicinesCount(int count) {
    return '$count medicines';
  }

  @override
  String get noMedicinesAdded => 'No medicines added';

  @override
  String get addYourFirstMedicine => 'Add your first medicine to continue';

  @override
  String get addMedicineStep => 'Add Medicine';

  @override
  String get addAnotherMedicine => 'Add Another Medicine';

  @override
  String get reviewPrescription => 'Review Prescription';

  @override
  String prescriptionDuration(int days) {
    return '$days days';
  }

  @override
  String get schedulePreview => 'Schedule Preview';

  @override
  String get scheduleAutoGenerated =>
      'Schedule is auto-generated based on medicine frequency';

  @override
  String get morningTime => 'Morning';

  @override
  String get afternoonTime => 'Afternoon';

  @override
  String get nightTime => 'Night';

  @override
  String get savePrescription => 'Save Prescription';

  @override
  String get ocrPatientInfoSection => 'Patient Information';

  @override
  String get ocrPatientName => 'Patient Name';

  @override
  String get ocrPatientKhmerName => 'Patient Name (Khmer)';

  @override
  String get ocrPatientId => 'Patient ID';

  @override
  String get ocrPatientAge => 'Age';

  @override
  String get ocrPatientGender => 'Gender';

  @override
  String get prescriptionCreatedSuccess => 'Prescription Created Successfully';

  @override
  String get yourScheduleReady => 'Your medication schedule is ready';

  @override
  String get viewSchedule => 'View Schedule';

  @override
  String get goHome => 'Go Home';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadReportDescription =>
      'Download your activity report as a PDF. Available on Premium plans.';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get pdfReady => 'Report PDF is ready';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get familyAlertsRequirePremium =>
      'Family alerts require a Premium plan. Upgrade to get notified when your loved ones miss a dose.';

  @override
  String get upgradeToPremiumForFamilyAlerts => 'Upgrade to Premium';

  @override
  String get notifReminderTitle => 'Medication Reminder';

  @override
  String get notifReminderRetryTag => ' (Reminder)';

  @override
  String get notifSnoozedTitle => 'Medication Reminder (Snoozed)';

  @override
  String get notifPeriodMorning => 'Morning';

  @override
  String get notifPeriodAfternoon => 'Afternoon';

  @override
  String get notifPeriodEvening => 'Evening';

  @override
  String get notifPeriodNight => 'Night';

  @override
  String get notifPeriodDose => 'Dose';

  @override
  String notifSingleBody(String name, String dosage, String period) {
    return 'Time to take $name ($dosage) - $period';
  }

  @override
  String notifBatchBody(String period) {
    return '$period medicines:';
  }

  @override
  String get notifSnoozedBodySingle =>
      'You snoozed your medication reminder. Please take your medicine now.';

  @override
  String get notifSnoozedBodyBatch =>
      'You snoozed your medication reminder. Please take your medicines now.';

  @override
  String get notifActionMarkTaken => 'Mark as Taken';

  @override
  String get notifActionSnooze => 'Snooze 10min';

  @override
  String get notifActionSkip => 'Skip';

  @override
  String get notifChannelDoseRemindersName => 'Dose Reminders';

  @override
  String get notifChannelDoseRemindersDesc =>
      'Reminders to take your medication';

  @override
  String get notifChannelBatchRemindersName => 'Batch Reminders';

  @override
  String get notifChannelBatchRemindersDesc =>
      'Reminders for medication batch groups';

  @override
  String get notifChannelGeneralName => 'General';

  @override
  String get notifChannelGeneralDesc => 'General app notifications';

  @override
  String get notifTestTitle => 'Test Notification';

  @override
  String get notifTestBody =>
      'This is a test reminder. Action buttons work correctly.';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get testNotificationSent => 'Test notification sent!';
}
