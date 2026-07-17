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
  String get foundationNote => 'لا توجد ميزات مالية حتى الآن. المرحلة الثانية ستُضيف سجل الحسابات.';

  @override
  String get errorNetwork => 'حدث خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مجدداً.';

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
  String get memberSpouseLoginNote => 'ملاحظة: تسجيل دخول منفصل للزوج/ة غير متاح في الإصدار الأول.';

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
  String get errorOpeningBalanceNegative => 'الرصيد الافتتاحي لا يمكن أن يكون سالباً.';

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
  String get errorValidationGeneric => 'بيانات غير صالحة. يرجى التحقق من المدخلات.';

  @override
  String get errorMoneyInvalidFormat => 'صيغة المبلغ غير صحيحة.';

  @override
  String get errorMoneyExcessDecimals => 'عدد الخانات العشرية يتجاوز دقة العملة.';

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
  String get protectedWithdrawalWarning => 'تحذير: هذا صندوق محمي. السحب يتطلب مسوّغاً.';

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
  String get errorWithdrawalReasonRequired => 'يُشترط ذكر سبب غير فارغ لسحب الصندوق المحمي.';

  @override
  String get errorWithdrawalAcknowledgmentRequired => 'يجب تأكيد الإشعار الخاص بالصندوق المحمي.';

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
  String get dashboardPeriodNoActivity => 'لا توجد حركة دخل أو مصروفات في هذه الفترة.';

  @override
  String get dashboardScopePersonal => 'الإنفاق الشخصي';

  @override
  String get dashboardScopeSpouse => 'إنفاق الزوج/ة';

  @override
  String get dashboardScopeHousehold => 'مصاريف المنزل';

  @override
  String get dashboardScopeChild => 'مصاريف الأطفال';

  @override
  String get dashboardScopeNoActivity => 'لا توجد بيانات نطاق الإنفاق لهذه الفترة.';

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
  String get dashboardNegativeBalanceWarning => 'رصيد سالب — مشكلة في سلامة البيانات';

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
  String get reportTransferNote => 'التحويلات غير مضمّنة في إجماليات الدخل أو المصروفات.';

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
  String get budgetOverlapNote => 'يمكن أن تتداخل الميزانيات — كل ميزانية مستقلة';

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
  String get budgetEmpty => 'لا توجد ميزانيات بعد. أنشئ ميزانية للبدء في التخطيط.';

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
  String get errorBudgetEndBeforeStart => 'يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء';

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
  String get errorGoalSourceIsProtected => 'لا يُسمح بالتمويل من حساب أطفال محمي';

  @override
  String get errorGoalSourceIsReserve => 'لا يمكن تمويل هدف من احتياطي هدف آخر';

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
}
