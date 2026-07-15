// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Money Manager';

  @override
  String get foundationTitle => 'Foundation Phase';

  @override
  String get foundationSubtitle => 'Project infrastructure is ready.';

  @override
  String get foundationLanguageLabel => 'Language';

  @override
  String get foundationThemeLabel => 'Theme';

  @override
  String get foundationDirectionLabel => 'Direction';

  @override
  String get foundationSwitchToArabic => 'العربية';

  @override
  String get foundationSwitchToEnglish => 'English';

  @override
  String get foundationThemeLight => 'Light';

  @override
  String get foundationThemeDark => 'Dark';

  @override
  String get foundationDirectionLtr => 'LTR';

  @override
  String get foundationDirectionRtl => 'RTL';

  @override
  String get foundationNote =>
      'No financial features exist yet. Phase 2 will introduce the ledger.';

  @override
  String get errorNetwork =>
      'A network error occurred. Please check your connection and try again.';

  @override
  String get errorAuth => 'Your session is invalid. Please sign in again.';

  @override
  String get errorStorage =>
      'A local storage error occurred. Please try again.';

  @override
  String get errorUnknown => 'An unexpected error occurred. Please try again.';
}
