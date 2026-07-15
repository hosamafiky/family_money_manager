// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مدير مالية الأسرة';

  @override
  String get foundationTitle => 'مرحلة البنية التحتية';

  @override
  String get foundationSubtitle => 'البنية التحتية للمشروع جاهزة.';

  @override
  String get foundationLanguageLabel => 'اللغة';

  @override
  String get foundationThemeLabel => 'المظهر';

  @override
  String get foundationDirectionLabel => 'اتجاه النص';

  @override
  String get foundationSwitchToArabic => 'العربية';

  @override
  String get foundationSwitchToEnglish => 'English';

  @override
  String get foundationThemeLight => 'فاتح';

  @override
  String get foundationThemeDark => 'داكن';

  @override
  String get foundationDirectionLtr => 'يسار إلى يمين';

  @override
  String get foundationDirectionRtl => 'يمين إلى يسار';

  @override
  String get foundationNote =>
      'لا توجد ميزات مالية حتى الآن. المرحلة الثانية ستُضيف سجل الحسابات.';

  @override
  String get errorNetwork =>
      'حدث خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مجدداً.';

  @override
  String get errorAuth => 'جلستك منتهية الصلاحية. يرجى تسجيل الدخول مجدداً.';

  @override
  String get errorStorage => 'حدث خطأ في التخزين المحلي. يرجى المحاولة مجدداً.';

  @override
  String get errorUnknown => 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.';
}
