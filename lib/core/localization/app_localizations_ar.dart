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

  @override
  String get foundationDetailTitle => 'تفاصيل البنية';

  @override
  String foundationDetailProbeLabel(String probeId) {
    return 'مسبار: $probeId';
  }

  @override
  String get navAccounts => 'الحسابات';

  @override
  String get navMembers => 'الأسرة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get accountsTitle => 'الحسابات';

  @override
  String get accountsEmpty => 'لا توجد حسابات بعد. أنشئ حسابك الأول.';

  @override
  String get accountsAddButton => 'إضافة حساب';

  @override
  String get accountsTotalSpendable => 'إجمالي المتاح للإنفاق';

  @override
  String get accountsTotalProtected => 'إجمالي المحمي';

  @override
  String get accountTypePersonalCash => 'محفظة نقدية شخصية';

  @override
  String get accountTypeSpouseCash => 'محفظة الزوج/ة';

  @override
  String get accountTypeHouseholdCash => 'نقدية المنزل';

  @override
  String get accountTypeHomeSavings => 'مدخرات المنزل';

  @override
  String get accountTypeBankAccount => 'حساب بنكي';

  @override
  String get accountTypeMobileWallet => 'محفظة موبايل';

  @override
  String get accountTypeChildFund => 'صندوق حماية الطفل';

  @override
  String get accountCreateTitle => 'حساب جديد';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get accountOwner => 'المالك';

  @override
  String get accountCurrency => 'العملة';

  @override
  String get accountOpeningBalance => 'الرصيد الافتتاحي';

  @override
  String get accountNotes => 'ملاحظات';

  @override
  String get accountProtectedWarning =>
      'هذا الحساب محمي. الأموال المودعة به ليست متاحة للإنفاق العادي.';

  @override
  String get accountChildFundConfirmTitle => 'تأكيد إنشاء صندوق الطفل';

  @override
  String get accountChildFundConfirmBody =>
      'سيتم حماية الأموال في هذا الحساب وتخصيصها للطفل. لا يمكن استخدامها للإنفاق العادي.';

  @override
  String get accountDetailTitle => 'تفاصيل الحساب';

  @override
  String get accountDetailBalance => 'الرصيد الحالي';

  @override
  String get accountDetailHistory => 'السجل المالي';

  @override
  String get accountDetailHistoryEmpty => 'لا توجد حركات مالية بعد.';

  @override
  String get accountArchive => 'أرشفة الحساب';

  @override
  String get accountArchiveConfirm => 'هل أنت متأكد من أرشفة هذا الحساب؟';

  @override
  String get accountArchiveError => 'لا يمكن أرشفة حساب برصيد غير صفري.';

  @override
  String get membersTitle => 'أفراد الأسرة';

  @override
  String get memberPrimaryUser => 'المستخدم الأساسي';

  @override
  String get memberSpouse => 'الزوج/ة';

  @override
  String get memberChild => 'طفل';

  @override
  String get memberAddSpouse => 'إضافة زوج/ة';

  @override
  String get memberAddChild => 'إضافة طفل';

  @override
  String get memberName => 'الاسم';

  @override
  String get memberRename => 'تغيير الاسم';

  @override
  String get memberArchive => 'أرشفة العضو';

  @override
  String get memberSpouseLoginNote =>
      'ملاحظة: تسجيل دخول منفصل للزوج/ة غير متاح في الإصدار الأول.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get protectedLabel => 'محمي';

  @override
  String get spendableLabel => 'متاح للإنفاق';

  @override
  String get archivedLabel => 'مؤرشف';

  @override
  String get loadingLabel => 'جارٍ التحميل...';

  @override
  String get balanceLabel => 'الرصيد';

  @override
  String get errorGeneric => 'حدث خطأ. يرجى المحاولة مجدداً.';

  @override
  String get errorAccountNameEmpty => 'اسم الحساب مطلوب.';

  @override
  String get errorOpeningBalanceNegative =>
      'الرصيد الافتتاحي لا يمكن أن يكون سالباً.';

  @override
  String get errorAccountDuplicate => 'حساب بهذا المعرف موجود مسبقاً.';

  @override
  String get errorArchiveNonzeroBalance => 'لا يمكن أرشفة حساب برصيد غير صفري.';

  @override
  String get errorAccountAlreadyArchived => 'الحساب مؤرشف مسبقاً.';

  @override
  String get errorMemberNameEmpty => 'اسم العضو مطلوب.';

  @override
  String get errorSpouseDuplicate => 'يوجد زوج/ة مسجل مسبقاً في هذه الأسرة.';

  @override
  String get errorCannotArchivePrimaryUser => 'لا يمكن أرشفة المستخدم الأساسي.';

  @override
  String get errorMemberAlreadyArchived => 'العضو مؤرشف مسبقاً.';

  @override
  String get errorValidationGeneric =>
      'بيانات غير صالحة. يرجى التحقق من المدخلات.';

  @override
  String get errorMoneyInvalidFormat => 'صيغة المبلغ غير صحيحة.';

  @override
  String get errorMoneyExcessDecimals =>
      'عدد الخانات العشرية يتجاوز دقة العملة.';

  @override
  String get errorMoneyOverflow => 'المبلغ كبير جداً.';

  @override
  String get navTransactions => 'المعاملات';

  @override
  String get transactionsTitle => 'المعاملات';

  @override
  String get transactionsEmpty => 'لا توجد معاملات بعد.';

  @override
  String get transactionsFilterAll => 'الكل';

  @override
  String get transactionTypeIncome => 'دخل';

  @override
  String get transactionTypeExpense => 'مصروف';

  @override
  String get transactionTypeTransfer => 'تحويل';

  @override
  String get transactionTypeOpeningBalance => 'رصيد افتتاحي';

  @override
  String get transactionTypeAdjustment => 'تسوية';

  @override
  String get transactionTypeReversal => 'عكس عملية';

  @override
  String get transactionReversed => 'معكوسة';

  @override
  String get createTransactionTitle => 'معاملة جديدة';

  @override
  String get createIncomeTitle => 'سجّل دخلاً';

  @override
  String get createExpenseTitle => 'سجّل مصروفاً';

  @override
  String get createTransferTitle => 'حوّل أموالاً';

  @override
  String get incomeFormTitle => 'تفاصيل الدخل';

  @override
  String get expenseFormTitle => 'تفاصيل المصروف';

  @override
  String get transferFormTitle => 'تفاصيل التحويل';

  @override
  String get reviewTitle => 'مراجعة وتأكيد';

  @override
  String get fieldDestinationAccount => 'الحساب المستقبل';

  @override
  String get fieldSourceAccount => 'حساب المصدر';

  @override
  String get fieldPaymentAccount => 'حساب الدفع';

  @override
  String get fieldAmount => 'المبلغ';

  @override
  String get fieldCategory => 'الفئة';

  @override
  String get fieldSpender => 'المنفق';

  @override
  String get fieldBeneficiary => 'المستفيد';

  @override
  String get fieldScope => 'النطاق';

  @override
  String get fieldEffectiveDate => 'التاريخ';

  @override
  String get fieldNote => 'ملاحظة (اختياري)';

  @override
  String get fieldRecurring => 'متكرر';

  @override
  String get recurringOneTime => 'مرة واحدة';

  @override
  String get recurringYes => 'متكرر (الجدولة غير مفعّلة بعد)';

  @override
  String get scopePersonal => 'شخصي';

  @override
  String get scopeSpouse => 'زوج/ة';

  @override
  String get scopeHousehold => 'المنزل';

  @override
  String get scopeChild => 'طفل';

  @override
  String get catGroceries => 'بقالة';

  @override
  String get catHousing => 'سكن';

  @override
  String get catUtilities => 'خدمات منزلية';

  @override
  String get catTransportation => 'مواصلات';

  @override
  String get catHealth => 'صحة';

  @override
  String get catEducation => 'تعليم';

  @override
  String get catChildExpenses => 'مصاريف الأطفال';

  @override
  String get catPersonalSpending => 'إنفاق شخصي';

  @override
  String get catSpouseSpending => 'إنفاق الزوج/ة';

  @override
  String get catGiftsAndDonations => 'هدايا وتبرعات';

  @override
  String get catOtherExpense => 'مصروف آخر';

  @override
  String get catSalary => 'راتب';

  @override
  String get catBusinessIncome => 'دخل أعمال';

  @override
  String get catGiftReceived => 'هدية مستلمة';

  @override
  String get catInterestIncome => 'دخل فوائد';

  @override
  String get catOtherIncome => 'دخل آخر';

  @override
  String get protectedWithdrawalWarning =>
      'تحذير: هذا صندوق محمي. السحب يتطلب مسوّغاً.';

  @override
  String get fieldWithdrawalReason => 'سبب السحب';

  @override
  String get fieldAcknowledgeWarning => 'أفهم أن هذا صندوق محمي';

  @override
  String get fieldConfirmWithdrawal => 'أؤكد أن هذا السحب ضروري';

  @override
  String get errorCategoryRequired => 'يرجى اختيار الفئة.';

  @override
  String get errorSpenderRequired => 'يرجى اختيار المنفق.';

  @override
  String get errorBeneficiaryRequired => 'يرجى اختيار المستفيد.';

  @override
  String get errorScopeRequired => 'يرجى اختيار النطاق.';

  @override
  String get errorInsufficientFunds => 'رصيد الحساب غير كافٍ.';

  @override
  String get errorSameAccount => 'يجب أن يكون الحساب المصدر والمستقبل مختلفين.';

  @override
  String get errorCurrencyMismatch => 'يجب أن يستخدم الحسابان نفس العملة.';

  @override
  String get errorAccountArchived => 'هذا الحساب مؤرشف ولا يقبل معاملات جديدة.';

  @override
  String get errorWithdrawalReasonRequired =>
      'يُشترط ذكر سبب غير فارغ لسحب الصندوق المحمي.';

  @override
  String get errorWithdrawalAcknowledgmentRequired =>
      'يجب تأكيد الإشعار الخاص بالصندوق المحمي.';

  @override
  String get errorWithdrawalConfirmationRequired => 'يجب تأكيد عملية السحب.';

  @override
  String get spouseWalletSummaryTitle => 'ملخص محفظة الزوج/ة';

  @override
  String get spouseWalletFunded => 'إجمالي المُحوَّل';

  @override
  String get spouseWalletSpent => 'إجمالي المُنفَق';

  @override
  String get spouseWalletReturned => 'إجمالي المُعاد';

  @override
  String get spouseWalletDerivedBalance => 'الرصيد المحتسب';

  @override
  String get actionRecordIncome => 'سجّل دخلاً';

  @override
  String get actionRecordExpense => 'سجّل مصروفاً';

  @override
  String get actionTransfer => 'حوّل أموالاً';

  @override
  String get transactionDetailTitle => 'تفاصيل المعاملة';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get dashboardTitle => 'الرئيسية';

  @override
  String get dashboardSpendableBalances => 'الأرصدة المتاحة';

  @override
  String get dashboardProtectedBalances => 'الأرصدة المحمية';

  @override
  String get dashboardNoSpendable => 'لا توجد حسابات متاحة للإنفاق.';

  @override
  String get dashboardNoProtected => 'لا توجد حسابات محمية.';

  @override
  String get dashboardPeriodIncome => 'الدخل';

  @override
  String get dashboardPeriodExpenses => 'المصروفات';

  @override
  String get dashboardPeriodNet => 'الصافي';

  @override
  String get dashboardPeriodNoActivity =>
      'لا توجد حركة دخل أو مصروفات في هذه الفترة.';

  @override
  String get dashboardScopePersonal => 'الإنفاق الشخصي';

  @override
  String get dashboardScopeSpouse => 'إنفاق الزوج/ة';

  @override
  String get dashboardScopeHousehold => 'مصاريف المنزل';

  @override
  String get dashboardScopeChild => 'مصاريف الأطفال';

  @override
  String get dashboardScopeNoActivity =>
      'لا توجد بيانات نطاق الإنفاق لهذه الفترة.';

  @override
  String get dashboardSpouseWallet => 'محفظة الزوج/ة';

  @override
  String get dashboardSpouseWalletFunded => 'موّل';

  @override
  String get dashboardSpouseWalletSpent => 'أُنفق';

  @override
  String get dashboardSpouseWalletReturned => 'أُعيد';

  @override
  String get dashboardSpouseWalletBalance => 'الرصيد الحالي';

  @override
  String get dashboardNoSpouseWallet => 'لا توجد محفظة للزوج/ة.';

  @override
  String get dashboardRecentActivity => 'آخر المعاملات';

  @override
  String get dashboardNoRecentActivity => 'لا توجد معاملات حديثة.';

  @override
  String get dashboardViewAll => 'عرض الكل';

  @override
  String get dashboardPeriodCurrentMonth => 'هذا الشهر';

  @override
  String get dashboardPeriodPreviousMonth => 'الشهر الماضي';

  @override
  String get dashboardPeriodCurrentYear => 'هذا العام';

  @override
  String get dashboardPeriodCustom => 'مخصص';

  @override
  String get dashboardNegativeBalanceWarning =>
      'رصيد سالب — مشكلة في سلامة البيانات';

  @override
  String get dashboardChildProtected => 'الطفل (محمي)';

  @override
  String get dashboardRefresh => 'تحديث';

  @override
  String get dashboardLoading => 'جارٍ تحميل الرئيسية...';

  @override
  String get dashboardError => 'تعذّر تحميل الملخص المالي.';

  @override
  String get dashboardRetry => 'إعادة المحاولة';

  @override
  String get dashboardPeriodLabel => 'الفترة';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportIncomeExpenseTitle => 'الدخل والمصروفات';

  @override
  String get reportAttributionTitle => 'نسب الإنفاق';

  @override
  String get reportCategoriesTitle => 'الفئات';

  @override
  String get reportAccountsTitle => 'تدفقات الحسابات';

  @override
  String get reportHomeSavingsTitle => 'مدخرات المنزل';

  @override
  String get reportSpouseWalletTitle => 'محفظة الزوج/ة';

  @override
  String get reportProtectedFundsTitle => 'الأموال المحمية';

  @override
  String get reportGrossIncome => 'الدخل الإجمالي';

  @override
  String get reportGrossExpense => 'المصروفات الإجمالية';

  @override
  String get reportNetIncome => 'صافي الدخل';

  @override
  String get reportNetExpense => 'صافي المصروفات';

  @override
  String get reportReversalEffect => 'أثر العكس';

  @override
  String get reportNetCashFlow => 'صافي التدفق النقدي';

  @override
  String get reportSpenderSection => 'حسب المنفق';

  @override
  String get reportBeneficiarySection => 'حسب المستفيد';

  @override
  String get reportScopeSection => 'حسب النطاق';

  @override
  String get reportOpeningBalance => 'الرصيد الافتتاحي';

  @override
  String get reportClosingBalance => 'الرصيد الختامي';

  @override
  String get reportCurrentBalance => 'الرصيد الحالي';

  @override
  String get reportFunded => 'موّل';

  @override
  String get reportSpent => 'أُنفق';

  @override
  String get reportReturned => 'أُعيد';

  @override
  String get reportWithdrawals => 'السحوبات';

  @override
  String get reportWithdrawalReason => 'السبب';

  @override
  String get reportBeneficiary => 'المستفيد';

  @override
  String get reportDrillDown => 'عرض المعاملات';

  @override
  String get reportEmpty => 'لا توجد بيانات لهذه الفترة.';

  @override
  String get reportError => 'تعذّر تحميل التقرير.';

  @override
  String get reportRefresh => 'تحديث';

  @override
  String get reportCurrencySeparate => 'الإجماليات مفصّلة بالعملة';

  @override
  String get reportTransferNote =>
      'التحويلات غير مضمّنة في إجماليات الدخل أو المصروفات.';

  @override
  String get reportReversalNote => 'آثار العكس معروضة بشكل منفصل.';

  @override
  String get reportPeriodClosingBalance => 'الرصيد الختامي للفترة';

  @override
  String get reportAuditDrillDown => 'عرض التدقيق';

  @override
  String reportTransactionCount(int count) {
    return '$count معاملات';
  }

  @override
  String get reportViewReports => 'عرض التقارير';

  @override
  String get onboardingSubtitle => 'مرحباً! أدخل اسمك لبدء الإعداد.';

  @override
  String get onboardingNameLabel => 'اسمك';

  @override
  String get onboardingNameHint => 'مثال: أحمد';

  @override
  String get onboardingStartButton => 'ابدأ';

  @override
  String get onboardingGenericError => 'حدث خطأ. يرجى المحاولة مجدداً.';

  @override
  String get budgetsTitle => 'الميزانيات';

  @override
  String get budgetNew => 'ميزانية جديدة';

  @override
  String get budgetName => 'اسم الميزانية';

  @override
  String get budgetCurrency => 'العملة';

  @override
  String get budgetLimit => 'الحد الشهري';

  @override
  String get budgetLimitFixed => 'حد الميزانية';

  @override
  String get budgetPeriodMonthly => 'شهرية (متكررة)';

  @override
  String get budgetPeriodFixed => 'فترة محددة';

  @override
  String get budgetStartDate => 'تاريخ البدء';

  @override
  String get budgetEndDate => 'تاريخ الانتهاء';

  @override
  String get budgetCategoryFilter => 'الفئة (اختياري)';

  @override
  String get budgetScopeFilter => 'النطاق (اختياري)';

  @override
  String get budgetSpenderFilter => 'المُنفق (اختياري)';

  @override
  String get budgetBeneficiaryFilter => 'المستفيد (اختياري)';

  @override
  String get budgetAccountFilter => 'حساب الدفع (اختياري)';

  @override
  String get budgetOverlapNote =>
      'يمكن أن تتداخل الميزانيات — كل ميزانية مستقلة';

  @override
  String get budgetStatusNoSpending => 'لا إنفاق';

  @override
  String get budgetStatusOnTrack => 'في المسار الصحيح';

  @override
  String get budgetStatusNearLimit => 'قرب الحد';

  @override
  String get budgetStatusLimitReached => 'تم الوصول للحد';

  @override
  String get budgetStatusOverBudget => 'تجاوز الميزانية';

  @override
  String get budgetConsumed => 'المُنفق';

  @override
  String get budgetRemaining => 'المتبقي';

  @override
  String budgetPercent(int percent) {
    return '$percent٪ مُستخدم';
  }

  @override
  String get budgetReversalNote => 'المبالغ المُعادة تُحتسب كصفر في الاستهلاك';

  @override
  String get budgetEmpty =>
      'لا توجد ميزانيات بعد. أنشئ ميزانية للبدء في التخطيط.';

  @override
  String get budgetArchived => 'مؤرشف';

  @override
  String get budgetArchive => 'أرشفة الميزانية';

  @override
  String get budgetRestore => 'استعادة الميزانية';

  @override
  String get budgetPreviousPeriods => 'الفترات السابقة';

  @override
  String get budgetNoMatching => 'لا توجد نفقات مطابقة في هذه الفترة';

  @override
  String get errorBudgetNameEmpty => 'اسم الميزانية مطلوب';

  @override
  String get errorBudgetLimitZero => 'يجب أن يكون حد الميزانية أكبر من صفر';

  @override
  String get errorBudgetEndBeforeStart =>
      'يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء';

  @override
  String get errorBudgetCurrencyRequired => 'العملة مطلوبة';

  @override
  String get goalsTitle => 'الأهداف';

  @override
  String get goalNew => 'هدف جديد';

  @override
  String get goalName => 'اسم الهدف';

  @override
  String get goalPurpose => 'الغرض';

  @override
  String get goalCurrency => 'العملة';

  @override
  String get goalTarget => 'المبلغ المستهدف';

  @override
  String get goalTargetDate => 'تاريخ الهدف (اختياري)';

  @override
  String get goalBeneficiary => 'المستفيد (اختياري)';

  @override
  String get goalInitialFunding => 'تمويل أولي (اختياري)';

  @override
  String get goalInitialFundingSource => 'الحساب المصدر';

  @override
  String get goalInitialFundingAmount => 'المبلغ الأولي';

  @override
  String get goalStatusActive => 'نشط';

  @override
  String get goalStatusTargetReached => 'تم بلوغ الهدف';

  @override
  String get goalStatusCompleted => 'مكتمل';

  @override
  String get goalStatusArchived => 'مؤرشف';

  @override
  String get goalProgressNotStarted => 'لم يبدأ';

  @override
  String get goalProgressInProgress => 'جارٍ';

  @override
  String get goalProgressTargetReached => 'تم بلوغ الهدف';

  @override
  String get goalProgressOverfunded => 'ممول بزيادة';

  @override
  String get goalReserveBalance => 'المحجوز';

  @override
  String get goalRemaining => 'المتبقي';

  @override
  String get goalOverfunded => 'زيادة التمويل';

  @override
  String goalPercent(int percent) {
    return '$percent٪ ممول';
  }

  @override
  String get goalFundAction => 'إضافة أموال';

  @override
  String get goalReleaseAction => 'تحرير الأموال';

  @override
  String get goalCompleteAction => 'تعيين كمكتمل';

  @override
  String get goalArchiveAction => 'أرشفة';

  @override
  String get goalRestoreAction => 'استعادة';

  @override
  String get goalReleaseReason => 'سبب التحرير';

  @override
  String get goalMovementFunding => 'تمويل';

  @override
  String get goalMovementRelease => 'تحرير';

  @override
  String get goalRevisions => 'السجل';

  @override
  String get goalChildFundNote => 'أموال الأهداف ليست أموالاً محمية للأطفال';

  @override
  String get goalTransferNote => 'هذا تحويل داخلي — وليس مصروفاً';

  @override
  String get goalReleaseTransferNote => 'هذا تحويل داخلي — وليس دخلاً';

  @override
  String get goalEmpty => 'لا توجد أهداف بعد. أنشئ هدفاً للبدء في الادخار.';

  @override
  String get purposeEmergencyFund => 'صندوق الطوارئ';

  @override
  String get purposeHomePurchase => 'شراء منزل';

  @override
  String get purposeEducation => 'تعليم';

  @override
  String get purposeTravel => 'سفر';

  @override
  String get purposeMajorPurchase => 'شراء كبير';

  @override
  String get purposeFamilyEvent => 'مناسبة عائلية';

  @override
  String get purposeOther => 'أخرى';

  @override
  String get errorGoalNameEmpty => 'اسم الهدف مطلوب';

  @override
  String get errorGoalTargetZero => 'يجب أن يكون المبلغ المستهدف أكبر من صفر';

  @override
  String get errorGoalCurrencyRequired => 'العملة مطلوبة';

  @override
  String get errorGoalReleaseReasonEmpty => 'سبب التحرير مطلوب';

  @override
  String get errorGoalInsufficientReserve => 'رصيد احتياطي الهدف غير كافٍ';

  @override
  String get errorGoalArchiveNonzeroBalance =>
      'لا يمكن أرشفة هدف يحتوي على أموال. حرِّر جميع الأموال أولاً.';

  @override
  String get errorGoalSourceIsProtected =>
      'لا يُسمح بالتمويل من حساب أطفال محمي';

  @override
  String get errorGoalSourceIsReserve => 'لا يمكن تمويل هدف من احتياطي هدف آخر';

  @override
  String get errorGoalSourceNotSpendable =>
      'تمويل الهدف يتطلب حسابًا قابلًا للإنفاق';

  @override
  String get errorGoalDestinationNotSpendable =>
      'تحرير أموال الهدف يتطلب حساب وجهة قابلًا للإنفاق';

  @override
  String get goalFundTitle => 'إضافة أموال للهدف';

  @override
  String get goalReleaseTitle => 'تحرير أموال الهدف';

  @override
  String get goalSourceAccount => 'الحساب المصدر';

  @override
  String get goalDestinationAccount => 'الحساب الوجهة';

  @override
  String get goalAmount => 'المبلغ';

  @override
  String get goalProjectedBalance => 'الرصيد المتوقع';

  @override
  String get goalReservedBalances => 'احتياطيات الأهداف';

  @override
  String get certificatesTitle => 'الشهادات';

  @override
  String get certificateNew => 'شهادة جديدة';

  @override
  String get certificateEmpty =>
      'لا توجد شهادات حتى الآن. أضف واحدة لتتبع ودائعك لأجل.';

  @override
  String get certificateInstitution => 'المؤسسة';

  @override
  String get certificatePrincipal => 'الأصل';

  @override
  String get certificateProfit => 'العائد';

  @override
  String get certificateMaturityDate => 'تاريخ الاستحقاق';

  @override
  String get certificateStartDate => 'تاريخ البدء';

  @override
  String get certificateReference => 'المرجع / رقم الشهادة';

  @override
  String get certificateAnnualRate => 'المعدل السنوي (نقطة أساس)';

  @override
  String get certificateProfitFrequency => 'تكرار العائد';

  @override
  String get certificateSourceAccount => 'حساب التمويل';

  @override
  String get certificateDestinationAccount => 'الحساب الوجهة';

  @override
  String get certificateRedeem => 'استرداد';

  @override
  String get certificateRedeemTitle => 'استرداد الشهادة';

  @override
  String get certificateProfitTitle => 'تسجيل عائد';

  @override
  String get certificateRecordProfit => 'تسجيل عائد';

  @override
  String get certificateLifecycleActive => 'نشطة';

  @override
  String get certificateLifecycleRedeemed => 'مستردة';

  @override
  String get certificateLifecycleArchived => 'مؤرشفة';

  @override
  String get certificateTermNotStarted => 'لم تبدأ';

  @override
  String get certificateTermActive => 'ضمن المدة';

  @override
  String get certificateTermMatured => 'استحقت';

  @override
  String get certificateTermOverdue => 'متأخرة الاسترداد';

  @override
  String get certificateTermFullyRedeemed => 'مستردة بالكامل';

  @override
  String get certificateProfitFreqMonthly => 'شهري';

  @override
  String get certificateProfitFreqQuarterly => 'ربع سنوي';

  @override
  String get certificateProfitFreqSemiAnnual => 'نصف سنوي';

  @override
  String get certificateProfitFreqAnnual => 'سنوي';

  @override
  String get certificateProfitFreqAtMaturity => 'عند الاستحقاق';

  @override
  String get certificateProfitFreqOther => 'أخرى';

  @override
  String get certificatePrincipalBalance => 'رصيد الأصل';

  @override
  String get certificateOriginalPrincipal => 'الأصل الأصلي';

  @override
  String get certificateNote => 'ملاحظة';

  @override
  String get certificateAmount => 'المبلغ';

  @override
  String get certificatePrincipalSection => 'الأصل';

  @override
  String get certificateProfitSection => 'العائد';

  @override
  String get certificateRedeemPrincipalOnly => 'الأصل فقط';

  @override
  String get certificateRedeemProfitOnly => 'العائد فقط';

  @override
  String get certificateRedeemCombined => 'الأصل + العائد';

  @override
  String get certificateReviewTitle => 'مراجعة الشهادة';

  @override
  String get catCertificateProfit => 'عائد الشهادة';

  @override
  String get errorCertificateInstitutionRequired => 'اسم المؤسسة مطلوب';

  @override
  String get errorCertificatePrincipalZero => 'يجب أن يكون الأصل أكبر من صفر';

  @override
  String get errorCertificateCurrencyRequired => 'العملة مطلوبة';

  @override
  String get errorCertificateDatesRequired => 'تاريخا البدء والاستحقاق مطلوبان';

  @override
  String get errorCertificateMaturityBeforeStart =>
      'يجب أن يكون تاريخ الاستحقاق بعد تاريخ البدء';

  @override
  String get errorCertificateSourceRequired => 'حساب مصدر التمويل مطلوب';

  @override
  String get errorCertificateSourceIsProtected =>
      'لا يُسمح بالتمويل من حساب أطفال محمي';

  @override
  String get errorCertificateAccountNotAllowedAsSource =>
      'لا يمكن استخدام حساب الشهادة مصدرًا للتمويل';

  @override
  String get errorCertificateAccountNotAllowedAsDestination =>
      'لا يمكن استخدام حساب الشهادة وجهةً';

  @override
  String get errorCertificateAccountNotAllowedInOrdinaryTransaction =>
      'لا يمكن استخدام حسابات الشهادات في المعاملات العادية';

  @override
  String get errorCertificateArchived => 'الشهادة مؤرشفة';

  @override
  String get errorCertificateNotActive => 'الشهادة غير نشطة';

  @override
  String get errorCertificateArchiveNonzeroBalance =>
      'لا يمكن أرشفة شهادة بها أصل متبقٍ. استردها أولاً.';

  @override
  String get errorCertificateRestoreRequiresArchived =>
      'يجب أن تكون الشهادة مؤرشفة لاستعادتها';

  @override
  String get errorCertificateIdempotencyConflict => 'تعارض في إنشاء الشهادة';

  @override
  String get errorCertificateReversalRequiresActive =>
      'يجب أن تكون الشهادة نشطة لعكس الشراء';

  @override
  String get errorCertificateReversalNotAllowedAfterHistory =>
      'لا يمكن عكس الشراء بعد تسجيل عائد أو استرداد';

  @override
  String get errorCertificateProfitReversalInvalidType =>
      'العملية المستهدفة ليست عملية دخل عائد';

  @override
  String get errorCertificateRedemptionReversalNotSupported =>
      'عكس الاسترداد غير مدعوم';

  @override
  String get errorCertificateNotMatured => 'الشهادة لم تصل إلى تاريخ الاستحقاق';

  @override
  String get errorCertificateNoPrincipal => 'لا يوجد أصل متبقي لاسترداده';

  @override
  String get errorCertificateFullRedemptionOnly =>
      'يُسمح فقط بالاسترداد الكامل للأصل';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navPlanning => 'التخطيط';

  @override
  String get navReports => 'التقارير';

  @override
  String get navMore => 'المزيد';

  @override
  String get planningTitle => 'التخطيط';

  @override
  String get planningSubtitle => 'الميزانيات والأهداف والشهادات';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get moreSubtitle => 'الحسابات والعائلة والإعدادات';

  @override
  String get dashboardQuickActions => 'إجراءات سريعة';

  @override
  String get dashboardNeedsAttention => 'يحتاج انتباهك';

  @override
  String get dashboardHeldBalances => 'أرصدة محتفظ بها';

  @override
  String get dashboardCertificatePrincipal => 'أصل الشهادات';

  @override
  String get accountRestrictionCertificate =>
      'أصل شهادة — عبر مسارات الشهادات فقط';

  @override
  String get accountRestrictionGoalReserve => 'احتياطي هدف — يُدار عبر الأهداف';

  @override
  String get accountRestrictionProtected => 'محمي — قيود على السحب';

  @override
  String get formSectionAmount => 'المبلغ';

  @override
  String get formSectionAccount => 'الحساب';

  @override
  String get formSectionCategory => 'التصنيف';

  @override
  String get formSectionAttribution => 'الإسناد';

  @override
  String get formAdvancedDetails => 'تفاصيل إضافية';

  @override
  String get operationTypeIncome => 'دخل';

  @override
  String get operationTypeExpense => 'مصروف';

  @override
  String get operationTypeTransfer => 'تحويل';

  @override
  String get fieldOperationType => 'نوع العملية';

  @override
  String get transferInternalExplanation =>
      'هذا تحويل داخلي. ينقص رصيد المصدر ويزيد رصيد الوجهة. ليس دخلاً وليس مصروفاً.';

  @override
  String get incomeIncreasesBalance => 'يزيد هذا الدخل رصيد حساب الوجهة.';

  @override
  String get expenseDecreasesBalance => 'ينقص هذا المصروف رصيد حساب الدفع.';

  @override
  String get protectedWithdrawalReviewNote =>
      'ينقص الرصيد المحمي. يُسجَّل السبب والمستفيد ويبقى قابلاً للتدقيق.';

  @override
  String get retryAction => 'إعادة المحاولة';

  @override
  String get budgetDoesNotHoldMoney =>
      'الميزانيات تراقب الإنفاق. لا تحتفظ بالمال ولا تمنع المصروفات.';

  @override
  String get budgetOverlapIndependent =>
      'الميزانيات المتداخلة تُراقب بشكل مستقل.';

  @override
  String get budgetRestatedReversals =>
      'المصروفات المعكوسة تستخدم عرض الميزانية المُعاد بيانه كما هو موثّق.';

  @override
  String get goalReserveDedicated =>
      'يُنشأ حساب احتياطي مخصص لهذا الهدف. التمويل تحويل داخلي — إجمالي الأصول لا يزيد.';

  @override
  String get goalNotChildProtected => 'أموال الهدف ليست صناديق أطفال محمية.';

  @override
  String get goalCurrencyImmutable => 'لا يمكن تغيير العملة بعد الإنشاء.';

  @override
  String get certificatePrincipalNotExpense =>
      'نقل الأصل إلى شهادة ليس مصروفاً.';

  @override
  String get certificatePrincipalReturnNotIncome => 'إعادة الأصل ليست دخلاً.';

  @override
  String get filterClearAll => 'مسح الكل';

  @override
  String filterActiveCount(int count) {
    return '$count عوامل تصفية نشطة';
  }

  @override
  String get lifecycleStatusLabel => 'دورة الحياة';

  @override
  String get progressStatusLabel => 'التقدّم';

  @override
  String get errorAccountRequired => 'الحساب مطلوب.';

  @override
  String get errorAmountMustBePositive => 'يجب أن يكون المبلغ أكبر من صفر.';

  @override
  String get errorDateInvalid => 'يرجى إدخال تاريخ صالح.';

  @override
  String get errorHouseholdAlreadyInitialized => 'هذه الأسرة مُعدّة مسبقاً.';

  @override
  String get errorHouseholdIdEmpty => 'معرّف الأسرة مطلوب.';

  @override
  String get errorBudgetIdempotencyConflict => 'تعارض في إنشاء الميزانية.';

  @override
  String get errorBudgetDatesRequired => 'يرجى اختيار تاريخ البداية والنهاية.';

  @override
  String get errorBudgetDuplicate => 'توجد ميزانية بهذا الإعداد مسبقاً.';

  @override
  String get errorBudgetCreateFailed => 'تعذّر إنشاء الميزانية.';

  @override
  String get budgetPeriodTypeLabel => 'نوع الفترة';

  @override
  String get errorCertificateSourceInvalid => 'مصدر التمويل المحدد غير مسموح.';

  @override
  String get errorEarlyCompletionConfirmationRequired =>
      'يجب تأكيد الإكمال المبكر.';

  @override
  String get errorEarlyCompletionReasonRequired => 'سبب الإكمال المبكر مطلوب.';

  @override
  String get errorGoalArchived => 'هذا الهدف مؤرشف.';

  @override
  String get errorGoalIdempotencyConflict => 'تعارض في عملية الهدف.';

  @override
  String get errorGoalLifecycleRequiresTypedWorkflow =>
      'يتطلب تغيير دورة الحياة شاشة سير عمل الهدف.';

  @override
  String get errorGoalNormalCompletionRequiresTarget =>
      'يجب بلوغ الهدف قبل الإكمال العادي.';

  @override
  String get errorGoalNotActive => 'الهدف غير نشط.';

  @override
  String get errorGoalReserveNotAllowedInOrdinaryTransaction =>
      'لا يمكن استخدام حسابات احتياطي الهدف في المعاملات العادية.';

  @override
  String get errorGoalRestoreRequiresArchived =>
      'يجب أن يكون الهدف مؤرشفاً لاستعادته.';

  @override
  String get errorGoalReversalInvalidMovement =>
      'لا يمكن عكس هذه العملية للأهداف.';

  @override
  String get errorLifecycleEventConflict =>
      'تعارض في حدث دورة الحياة. حدّث الصفحة وحاول مجدداً.';

  @override
  String get errorOperationAlreadyReversed => 'تم عكس هذه العملية مسبقاً.';

  @override
  String get errorGoalSourceAccountRequired => 'يرجى اختيار حساب المصدر.';

  @override
  String get errorGoalDestinationAccountRequired => 'يرجى اختيار حساب الوجهة.';

  @override
  String get goalNotFound => 'الهدف غير موجود.';

  @override
  String get errorPageNotFound => 'الصفحة غير موجودة.';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String get certificateCurrency => 'العملة';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع.';

  @override
  String get accountTypeGoalReserve => 'احتياطي الهدف';

  @override
  String get accountTypeCertificate => 'حساب الشهادة';

  @override
  String get accountTypeGoldHolding => 'حيازة الذهب';

  @override
  String get accountTypeInvestment => 'حساب استثمار';

  @override
  String get accountTypeOtherAsset => 'أصل آخر';

  @override
  String get transactionTypeAssetPurchase => 'شراء أصل';

  @override
  String get transactionTypeAssetSale => 'بيع أصل';

  @override
  String get transactionTypeLiabilityCreation => 'إنشاء التزام';

  @override
  String get transactionTypeLiabilityRepayment => 'سداد التزام';

  @override
  String get transactionTypeCertificateFunding => 'تمويل الشهادة';

  @override
  String get transactionTypeCertificateMaturity => 'استحقاق الشهادة';

  @override
  String get transactionTypeInterestIncome => 'دخل فائدة';

  @override
  String get transactionTypeGoldPurchase => 'شراء ذهب';

  @override
  String get transactionTypeGoldSale => 'بيع ذهب';

  @override
  String get transactionTypeGoalFunding => 'تمويل الهدف';

  @override
  String get transactionTypeGoalWithdrawal => 'سحب من الهدف';

  @override
  String get transactionTypeChildFundDeposit => 'إيداع صندوق الطفل';

  @override
  String get transactionTypeChildFundWithdrawal => 'سحب من صندوق الطفل';

  @override
  String get transactionTypeSadaqah => 'صدقة';

  @override
  String get transactionTypeZakat => 'زكاة';

  @override
  String get scopeShared => 'مشترك';

  @override
  String get dashboardScopeShared => 'إنفاق مشترك';

  @override
  String get certificateEventCreated => 'تم الإنشاء';

  @override
  String get certificateEventPurchased => 'تم الشراء';

  @override
  String get certificateEventProfitReceived => 'تم استلام الربح';

  @override
  String get certificateEventRedeemed => 'تم الاسترداد';

  @override
  String get certificateEventArchived => 'تمت الأرشفة';

  @override
  String get certificateEventRestored => 'تمت الاستعادة';

  @override
  String get certificateEventDefinitionRevised => 'تم تعديل التعريف';

  @override
  String get certificateEventPurchaseReversed => 'تم عكس الشراء';

  @override
  String get certificateEventProfitReversed => 'تم عكس الربح';

  @override
  String get currencyEgp => 'جنيه مصري (EGP)';

  @override
  String get currencyUsd => 'دولار أمريكي (USD)';

  @override
  String get currencyEur => 'يورو (EUR)';

  @override
  String get currencyGbp => 'جنيه إسترليني (GBP)';

  @override
  String get currencySar => 'ريال سعودي (SAR)';

  @override
  String get currencyAed => 'درهم إماراتي (AED)';

  @override
  String get currencyJpy => 'ين ياباني (JPY)';

  @override
  String get currencyKwd => 'دينار كويتي (KWD)';

  @override
  String get currencyBhd => 'دينار بحريني (BHD)';

  @override
  String get currencyOmr => 'ريال عماني (OMR)';

  @override
  String get amountHidden => 'مبلغ مخفي';

  @override
  String get amountNotSpendable => 'غير قابل للصرف';

  @override
  String get amountHeld => 'محتجز';

  @override
  String progressUsedPercent(int percent) {
    return '$percent٪ مُستخدم';
  }

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get errorLedgerUnchanged =>
      'لم تُحفظ أي بيانات. سجلك سليم ولم يتغيّر.';

  @override
  String errorCodeLabel(String code) {
    return 'رمز الخطأ: $code';
  }

  @override
  String get accountRegionSpendable => 'قابل للصرف';

  @override
  String get accountRegionHeld => 'محتجز — غير قابل للصرف';

  @override
  String get dashboardAvailableToSpend => 'يمكنك صرف الآن';

  @override
  String get dashboardNoCombinedTotal =>
      'لا يوجد إجمالي موحّد — كل عملة مستقلة';

  @override
  String dashboardHeldSubtotal(String currency) {
    return 'إجمالي المحتجز — $currency';
  }

  @override
  String get dashboardHeldNotAdded =>
      'لا يُضاف إلى رصيدك المتاح — هذا مجموع داخل هذه المنطقة فقط';

  @override
  String get dashboardExcludedFromAvailable => 'غير محسوبة هنا';

  @override
  String get heldReasonCertificatePrincipal => 'أصل الشهادة';

  @override
  String get heldReasonGoalReserve => 'محتجز لهدف';

  @override
  String get heldReasonChildProtected => 'محمي';

  @override
  String get heldReasonOther => 'غير قابل للصرف';

  @override
  String dashboardFromAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count حساب',
      many: 'من $count حسابًا',
      few: 'من $count حسابات',
      two: 'من حسابين',
      one: 'من حساب واحد',
      zero: 'لا توجد حسابات',
    );
    return '$_temp0';
  }

  @override
  String dashboardHeldVaults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خزنة',
      many: '$count خزنة',
      few: '$count خزائن',
      two: 'خزنتان',
      one: 'خزنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String expenseReadBack(
    String amount,
    String category,
    String account,
    String spender,
    String scope,
  ) {
    return 'صرفت $amount على $category من $account — أنفقتها $spender لحساب $scope.';
  }

  @override
  String get reviewLedgerEffect => 'أثر هذه الحركة على السجل';

  @override
  String reviewDebitLabel(String description) {
    return 'مدين — $description';
  }

  @override
  String reviewCreditLabel(String description) {
    return 'دائن — $description';
  }

  @override
  String reviewBalanceAfterSave(String account) {
    return 'رصيد $account بعد الحفظ';
  }

  @override
  String get reviewAppendOnlyConsequence =>
      'بعد الحفظ لا يمكن الحذف — التصحيح يكون بحركة عكسية تبقى في السجل.';

  @override
  String expenseDefaultsLine(
    String account,
    String date,
    String spender,
    String scope,
  ) {
    return 'من $account · $date · المنفق $spender · $scope';
  }

  @override
  String get expenseMoreDetails =>
      'تفاصيل أكثر — المنفق، المستفيد، النطاق، ملاحظات، تكرار';

  @override
  String expenseSpenderNotOwnerHint(String spender) {
    return 'المنفق $spender والحساب باسم شخص آخر — ملاحظة قصيرة تسهّل المراجعة بعدين.';
  }

  @override
  String incomeReadBack(String amount, String category, String account) {
    return 'استلمت $amount من $category في $account.';
  }

  @override
  String transferReadBack(String amount, String source, String destination) {
    return 'حوّلت $amount من $source إلى $destination.';
  }

  @override
  String get errorReversalReasonRequired => 'اكتب سبب العكس — مطلوب.';

  @override
  String get errorReversalReasonTooLong =>
      'السبب طويل جداً — 280 حرف كحد أقصى.';

  @override
  String get errorReversalConflict =>
      'طلب عكس متعارض. حدّث الصفحة وحاول مجدداً.';

  @override
  String get errorReversalRequiresProtectedAudit =>
      'عكس الحركة دي هيسحب من مال محمي — لازم تعديه من شاشة السحب المحمي.';

  @override
  String get reversalSheetTitle => 'عكس حركة — مش حذف';

  @override
  String get reversalSheetIntro =>
      'الحركة الأصلية هتفضل في السجل زي ما هي. هنضيف حركة معاكسة تشير إليها، فيبقى التاريخ كامل وقابل للمراجعة.';

  @override
  String get reversalBeforeAfterTitle => 'قبل وبعد';

  @override
  String get reversalOriginalStaysLabel => 'تبقى — تُعلَّم كمعكوسة';

  @override
  String get reversalCounterEntryLabel => 'حركة عكسية · اليوم';

  @override
  String get reversalCounterEntryReference => 'تشير إلى الحركة أعلاه';

  @override
  String get reversalReasonLabel => 'سبب العكس — مطلوب';

  @override
  String get reversalReasonPermanenceNote =>
      'السبب يُسجَّل على الحركة العكسية بشكل دائم ويظهر لأي حد يفتحها.';

  @override
  String get reversalReasonPresetDuplicate => 'أُدخلت مرتين';

  @override
  String get reversalReasonPresetWrongAmount => 'مبلغ خطأ';

  @override
  String get reversalReasonPresetWrongAccount => 'حساب خطأ';

  @override
  String get reversalReasonPresetCancelledPurchase => 'اتلغت الشرائية';

  @override
  String get reversalConfirmAction => 'أضف الحركة العكسية';

  @override
  String get reversalNoDeleteNote => 'مفيش زر حذف في التطبيق، وده مقصود.';

  @override
  String get detailNoEditNoDeleteTitle => 'مفيش تعديل ومفيش حذف.';

  @override
  String get detailNoEditNoDeleteBody =>
      'الحركة دي جزء دائم من السجل. لو فيها غلط، بنضيف حركة عكسية تشير إليها — والاتنين يفضلوا ظاهرين.';

  @override
  String get detailLedgerEntriesTitle => 'قيود السجل — طرفان';

  @override
  String get detailLedgerEntriesOriginalTitle => 'قيود السجل — الأصل';

  @override
  String get detailEntriesStillInLedgerNote =>
      'القيود دي لسه في السجل — مش ممسوحة. الحركة العكسية ضافت قيدين مضادين، فبقى الصافي صفر بدون ما نلمس التاريخ.';

  @override
  String get detailReversedBannerTitle => 'الحركة دي معكوسة';

  @override
  String get detailAlreadyReversedNoAction =>
      'الحركة معكوسة بالفعل — مفيش إجراء تاني';

  @override
  String get detailChainTitle => 'سلسلة الحركة';

  @override
  String get detailChainOriginalLabel => 'الأصل';

  @override
  String get detailChainReversalLabel => 'الحركة العكسية';

  @override
  String get detailChainYouAreHere => 'أنت هنا';

  @override
  String get detailChainOpenEntry => 'افتحها';

  @override
  String get detailStatusPosted => 'مُسجَّلة';

  @override
  String get transactionRepeatAction => 'تكرار';

  @override
  String reversalNetEffectOn(String account) {
    return 'صافي الأثر على $account';
  }

  @override
  String detailReversedBannerBody(String date) {
    return 'اتعكست في $date. الأصل باقي كما هو، وأثرها على الرصيد صفر.';
  }

  @override
  String detailChainReasonBy(String reason, String author) {
    return 'السبب: $reason · بواسطة $author';
  }

  @override
  String detailRecordedAt(String timestamp) {
    return 'سُجِّلت في $timestamp';
  }

  @override
  String reversalSavedConfirmation(String net) {
    return 'تمت إضافة الحركة العكسية. الأصل باقي في السجل، والصافي بقى $net.';
  }

  @override
  String get detailAddReversalAction => 'أضف حركة عكسية';

  @override
  String get detailSectionTitle => 'التفاصيل';

  @override
  String detailChainStepOriginal(String step, String date) {
    return '$step · الأصل — $date';
  }

  @override
  String detailChainStepReversal(String step, String date) {
    return '$step · الحركة العكسية — $date';
  }

  @override
  String get transactionsGroupToday => 'اليوم';

  @override
  String get transactionsGroupYesterday => 'أمس';

  @override
  String get transactionsSummaryIncome => 'دخل';

  @override
  String get transactionsSummaryExpense => 'مصروف';

  @override
  String get transactionsSummaryTransfer => 'تحويل';

  @override
  String get transactionsTransferNotCounted => 'لا يؤثر على الدخل أو المصروف';

  @override
  String get transactionsReversedOriginalMeta =>
      'الأصل محفوظ — انظر الحركة المقابلة';

  @override
  String get transactionsEmptyFilteredTitle => 'مفيش حركة تطابق التصفية';

  @override
  String get transactionsErrorTitle => 'تعذّر تحميل الحركات';

  @override
  String transactionsSummaryCurrencyOnly(String currency) {
    return '$currency فقط · الحركات بعملات أخرى معروضة أدناه بعملتها';
  }

  @override
  String transactionsGroupCount(String count) {
    return '$count';
  }

  @override
  String transactionsReversalRefersTo(String date, String reason) {
    return 'تشير إلى حركة $date · السبب: $reason';
  }

  @override
  String transactionsCountAvailable(String count) {
    return 'عندك $count حركة';
  }

  @override
  String get transactionsFilterTitle => 'تصفية';

  @override
  String get transactionsFilterType => 'النوع';

  @override
  String get transactionsFilterShowReversed => 'إظهار الحركات المعكوسة';

  @override
  String get transactionsFilterAmountRange => 'المبلغ';

  @override
  String get transactionsFilterAmountPerCurrency =>
      'لكل عملة على حدة — الفلتر لا يقارن بين عملتين';

  @override
  String get transactionsFilterMin => 'من';

  @override
  String get transactionsFilterMax => 'إلى';

  @override
  String get transactionsSearchHint =>
      'ابحث في الوصف والملاحظات وأسماء الحسابات';

  @override
  String get transactionsSearchIgnoresPeriod => 'البحث يتجاهل الفترة المحددة';

  @override
  String get transactionsClearFilters => 'مسح كل التصفية';

  @override
  String get transactionsCancel => 'إلغاء';

  @override
  String transactionsFilterApply(String count) {
    return 'عرض $count حركة';
  }

  @override
  String transactionsClearFiltersCount(String count) {
    return 'مسح الكل ($count)';
  }

  @override
  String transactionsEmptyFilteredBody(String total) {
    return 'عندك $total حركة — بس مفيش حاجة تطابق التصفية دي.';
  }

  @override
  String get reportTransferIn => 'تحويل وارد';

  @override
  String get reportTransferOut => 'تحويل صادر';

  @override
  String get reportSpouseWalletFunded => 'محفظة الزوجة — تسليم';

  @override
  String get reportSpouseWalletReturned => 'محفظة الزوجة — مرتجع';

  @override
  String reportAuditFor(String beneficiary, String date) {
    return 'للمستفيد $beneficiary · $date';
  }

  @override
  String reportAuditForBy(String beneficiary, String recordedBy, String date) {
    return 'للمستفيد $beneficiary · بواسطة $recordedBy · $date';
  }

  @override
  String get reportDrillDownFiltered => 'معروض بتصفية من التقرير';

  @override
  String get reportDrillDownClear => 'عرض الكل';

  @override
  String get reportDoesNotReconcile => 'الأرقام دي مش مظبوطة';

  @override
  String get reportDoesNotReconcileBody =>
      'رصيد أول المدة زائد الحركات لا يساوي رصيد آخر المدة. الأرصدة نفسها صحيحة — المشكلة في تفصيل الفترة، فمتعتمدش على السطور دي لحد ما تتراجع.';

  @override
  String get transactionsFilterCategory => 'الفئة';

  @override
  String get transactionsFilterAccount => 'الحساب';

  @override
  String get transactionsFilterSpender => 'المنفق';

  @override
  String get transactionsFilterScope => 'النطاق';

  @override
  String get transactionsFilterCurrency => 'العملة';

  @override
  String get transactionsFilterAllAccounts => 'كل الحسابات';

  @override
  String get transactionsFilterAnyMember => 'أي فرد';

  @override
  String get datePickerTitle => 'اختر تاريخ';

  @override
  String get datePickerToday => 'النهاردة';

  @override
  String get datePickerYesterday => 'إمبارح';

  @override
  String get datePickerStartOfMonth => 'أول الشهر';

  @override
  String get datePickerConfirm => 'اختار';

  @override
  String get datePickerNoFuture => 'مفيش حركة بتتسجّل في المستقبل';
}
