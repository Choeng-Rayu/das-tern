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
    Locale('km'),
    Locale('en'),
  ];

  /// App brand name shown on splash, sign-in, and Android launcher.
  ///
  /// In km, this message translates to:
  /// **'ដាស់ធើន'**
  String get appName;

  /// No description provided for @commonContinue.
  ///
  /// In km, this message translates to:
  /// **'បន្ត'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In km, this message translates to:
  /// **'បោះបង់'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In km, this message translates to:
  /// **'រក្សាទុក'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In km, this message translates to:
  /// **'សាកល្បងម្តងទៀត'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In km, this message translates to:
  /// **'យល់ព្រម'**
  String get commonOk;

  /// No description provided for @commonLoading.
  ///
  /// In km, this message translates to:
  /// **'កំពុងផ្ទុក...'**
  String get commonLoading;

  /// No description provided for @commonOffline.
  ///
  /// In km, this message translates to:
  /// **'មិនមានបណ្តាញ'**
  String get commonOffline;

  /// No description provided for @homeTitle.
  ///
  /// In km, this message translates to:
  /// **'ផ្ទាំងគ្រប់គ្រង'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In km, this message translates to:
  /// **'សូមស្វាគមន៍មកកាន់ ដាស់ធើន'**
  String get homeWelcome;

  /// No description provided for @homeWelcomeSubtitle.
  ///
  /// In km, this message translates to:
  /// **'ការគ្រប់គ្រងវេជ្ជបញ្ជារបស់អ្នក នៅក្រោមការគ្រប់គ្រងរបស់អ្នក។'**
  String get homeWelcomeSubtitle;

  /// No description provided for @homePlaceholder.
  ///
  /// In km, this message translates to:
  /// **'មុខងារផ្សេងៗកំពុងត្រូវបានសាងសង់។'**
  String get homePlaceholder;

  /// No description provided for @settingsTitle.
  ///
  /// In km, this message translates to:
  /// **'ការកំណត់'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In km, this message translates to:
  /// **'ការបង្ហាញ'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In km, this message translates to:
  /// **'ពន្លឺ'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In km, this message translates to:
  /// **'ងងឹត'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In km, this message translates to:
  /// **'តាមប្រព័ន្ធ'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In km, this message translates to:
  /// **'ភាសា'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageKm.
  ///
  /// In km, this message translates to:
  /// **'ខ្មែរ'**
  String get settingsLanguageKm;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In km, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @dosesTaken.
  ///
  /// In km, this message translates to:
  /// **'បានទទួល'**
  String get dosesTaken;

  /// No description provided for @dosesMissed.
  ///
  /// In km, this message translates to:
  /// **'ខានទទួល'**
  String get dosesMissed;

  /// No description provided for @dosesSkipped.
  ///
  /// In km, this message translates to:
  /// **'បានរំលង'**
  String get dosesSkipped;

  /// No description provided for @dosesSnooze.
  ///
  /// In km, this message translates to:
  /// **'ពន្យារ'**
  String get dosesSnooze;

  /// No description provided for @adherenceGreenZone.
  ///
  /// In km, this message translates to:
  /// **'≥៩០%'**
  String get adherenceGreenZone;

  /// No description provided for @adherenceYellowZone.
  ///
  /// In km, this message translates to:
  /// **'៧០–៨៩%'**
  String get adherenceYellowZone;

  /// No description provided for @adherenceRedZone.
  ///
  /// In km, this message translates to:
  /// **'<៧០%'**
  String get adherenceRedZone;

  /// No description provided for @errorsNetwork.
  ///
  /// In km, this message translates to:
  /// **'មិនមានបណ្តាញ — សាកល្បងម្តងទៀត'**
  String get errorsNetwork;

  /// No description provided for @errorsPermissionDenied.
  ///
  /// In km, this message translates to:
  /// **'អនុញ្ញាតមិនបានគ្រប់គ្រាន់'**
  String get errorsPermissionDenied;

  /// No description provided for @errorsUnknown.
  ///
  /// In km, this message translates to:
  /// **'មានបញ្ហាមិនស្គាល់ — សូមសាកល្បងម្តងទៀត'**
  String get errorsUnknown;
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
