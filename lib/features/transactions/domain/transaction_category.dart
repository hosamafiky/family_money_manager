/// A stable, non-localized transaction category.
///
/// Category codes are stored in the database and must never change.
/// Display labels are resolved through the localization layer using the
/// corresponding `cat*` key (e.g. [TransactionCategory.groceries] → `catGroceries`).
enum TransactionCategory {
  // ── Expense ──────────────────────────────────────────────────────────────
  groceries('groceries', CategoryType.expense),
  housing('housing', CategoryType.expense),
  utilities('utilities', CategoryType.expense),
  transportation('transportation', CategoryType.expense),
  health('health', CategoryType.expense),
  education('education', CategoryType.expense),
  childExpenses('child_expenses', CategoryType.expense),
  personalSpending('personal_spending', CategoryType.expense),
  spouseSpending('spouse_spending', CategoryType.expense),
  giftsAndDonations('gifts_and_donations', CategoryType.expense),
  otherExpense('other_expense', CategoryType.expense),

  // ── Income ───────────────────────────────────────────────────────────────
  salary('salary', CategoryType.income),
  businessIncome('business_income', CategoryType.income),
  giftReceived('gift_received', CategoryType.income),
  interestIncome('interest_income', CategoryType.income),

  /// Profit paid on a savings certificate / fixed-term deposit (Phase 6A).
  certificateProfit('certificate_profit', CategoryType.income),
  otherIncome('other_income', CategoryType.income);

  const TransactionCategory(this.code, this.type);

  /// Stable database code. Never changes across app versions.
  final String code;

  /// Whether this is an expense or income category.
  final CategoryType type;

  /// Looks up a [TransactionCategory] by its stable [code].
  ///
  /// Throws [ArgumentError] for unknown codes.
  static TransactionCategory fromCode(String code) => values.firstWhere(
    (c) => c.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown category'),
  );

  bool get isExpense => type == CategoryType.expense;
  bool get isIncome => type == CategoryType.income;

  /// All expense categories in display order.
  static List<TransactionCategory> get expenseCategories =>
      values.where((c) => c.isExpense).toList();

  /// All income categories in display order.
  static List<TransactionCategory> get incomeCategories =>
      values.where((c) => c.isIncome).toList();
}

enum CategoryType { expense, income }
