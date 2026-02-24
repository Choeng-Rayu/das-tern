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
  String get unlockPremiumFeatures => 'Unlock premium features';

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
  String get upgradeToUnlock => 'Upgrade to unlock all features';

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
}
