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
    Locale('es', '419'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ya Pomodoro'**
  String get appTitle;

  /// No description provided for @pomodoroPhase.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroPhase;

  /// No description provided for @shortBreakPhase.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get shortBreakPhase;

  /// No description provided for @longBreakPhase.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreakPhase;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

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

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get resetButton;

  /// No description provided for @resetWorkButton.
  ///
  /// In en, this message translates to:
  /// **'Reset work'**
  String get resetWorkButton;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// No description provided for @cycleProgress.
  ///
  /// In en, this message translates to:
  /// **'Cycle {completed}/4'**
  String cycleProgress(int completed);

  /// No description provided for @pomodoroDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro (minutes)'**
  String get pomodoroDurationLabel;

  /// No description provided for @shortBreakDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get shortBreakDurationLabel;

  /// No description provided for @longBreakDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Long break (minutes)'**
  String get longBreakDurationLabel;

  /// No description provided for @showCycleProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Show cycle progress'**
  String get showCycleProgressLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanishLatam.
  ///
  /// In en, this message translates to:
  /// **'Español (LatAm)'**
  String get languageSpanishLatam;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @settingsLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Stop the timer to edit settings.'**
  String get settingsLockedMessage;

  /// No description provided for @invalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Use a value between 1 and 120.'**
  String get invalidDuration;

  /// No description provided for @notificationPhaseCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Phase complete'**
  String get notificationPhaseCompleteTitle;

  /// No description provided for @notificationPhaseCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your timer has moved to the next phase'**
  String get notificationPhaseCompleteBody;
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
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
        }
        break;
      }
  }

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
