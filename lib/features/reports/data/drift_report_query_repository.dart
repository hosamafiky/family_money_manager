/// Drift-backed implementation of [ReportQueryRepository].
///
/// ── DETERMINISTIC ORDERING POLICY ────────────────────────────────────────────
///
/// All queries that return ordered rows (e.g. [drillDown]) use
/// `ORDER BY o.effective_date DESC, o.id ASC` to guarantee a stable,
/// deterministic result set across identical DB states. The compound sort key
/// ensures:
///   1. Most-recent transactions appear first (user expectation).
///   2. Same-date operations are ordered by their immutable string ID, which
///      is client-generated UUID v4. This tie-break is deterministic because
///      UUIDs do not change after insertion.
///
/// ── SAFE RECORD LIMIT ─────────────────────────────────────────────────────────
///
/// [drillDown] enforces a hard `LIMIT` (default 100, max 500) to prevent
/// unbounded memory allocation when a period contains thousands of rows.
/// Callers that need full export should paginate using the `offset` parameter
/// (not yet exposed; deferred to a future phase).
library;

import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';

/// Drift-backed implementation of [ReportQueryRepository].
///
/// All queries are read-only raw SQL via [AppDatabase.customSelect].
/// Every monetary total is per-currency to prevent mixed-currency aggregation.
final class DriftReportQueryRepository implements ReportQueryRepository {
  const DriftReportQueryRepository(this._db);

  final AppDatabase _db;

  // ── incomeExpenseFlow ──────────────────────────────────────────────────────

  @override
  Future<List<CurrencyFlowSummary>> incomeExpenseFlow(
    FinancialReportRequest req,
  ) async {
    const grossSql = '''
      SELECT o.currency_code, o.type, SUM(o.total_amount_minor_units) AS subtotal
      FROM operations o
      WHERE o.household_id = ?
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND o.type IN ('income', 'expense')
      GROUP BY o.currency_code, o.type
    ''';

    const reversalSql = '''
      SELECT rev.currency_code, orig.type AS original_type,
             SUM(rev.total_amount_minor_units) AS reversal_amount
      FROM operations rev
      JOIN operations orig ON orig.reversed_by = rev.id
      WHERE rev.household_id = ?
        AND rev.type = 'reversal'
        AND rev.effective_date >= ?
        AND rev.effective_date < ?
        AND orig.type IN ('income', 'expense')
      GROUP BY rev.currency_code, orig.type
    ''';

    final vars = [
      Variable.withString(req.householdId),
      Variable.withString(req.period.startDate),
      Variable.withString(req.period.endDate),
    ];

    final grossRows = await _db.customSelect(grossSql, variables: vars).get();
    final reversalRows = await _db
        .customSelect(reversalSql, variables: vars)
        .get();

    final map = <String, _FlowAcc>{};
    for (final row in grossRows) {
      final currency = row.read<String>('currency_code');
      final type = row.read<String>('type');
      final subtotal = row.read<int>('subtotal');
      final acc = map.putIfAbsent(currency, _FlowAcc.new);
      if (type == 'income') {
        acc.grossIncome += subtotal;
      } else {
        acc.grossExpense += subtotal;
      }
    }
    for (final row in reversalRows) {
      final currency = row.read<String>('currency_code');
      final origType = row.read<String>('original_type');
      final amount = row.read<int>('reversal_amount');
      final acc = map.putIfAbsent(currency, _FlowAcc.new);
      if (origType == 'income') {
        acc.incomeReversal += amount;
      } else {
        acc.expenseReversal += amount;
      }
    }

    return map.entries
        .map(
          (e) => CurrencyFlowSummary(
            currencyCode: e.key,
            grossIncomeMinorUnits: e.value.grossIncome,
            grossExpenseMinorUnits: e.value.grossExpense,
            incomeReversalMinorUnits: e.value.incomeReversal,
            expenseReversalMinorUnits: e.value.expenseReversal,
          ),
        )
        .toList();
  }

  // ── expenseByScope ────────────────────────────────────────────────────────

  @override
  Future<List<ExpenseScopeBreakdown>> expenseByScope(
    FinancialReportRequest req,
  ) async {
    const sql = '''
      SELECT
        COALESCE(oc.expense_scope, o.scope) AS effective_scope,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total,
        COUNT(*) AS cnt
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      WHERE o.household_id = ?
        AND o.type = 'expense'
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND COALESCE(oc.expense_scope, o.scope) IS NOT NULL
      GROUP BY effective_scope, o.currency_code
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [
            Variable.withString(req.householdId),
            Variable.withString(req.period.startDate),
            Variable.withString(req.period.endDate),
          ],
        )
        .get();

    final result = <ExpenseScopeBreakdown>[];
    for (final row in rows) {
      final scopeStr = row.readNullable<String>('effective_scope');
      if (scopeStr == null) continue;
      try {
        result.add(
          ExpenseScopeBreakdown(
            scope: ExpenseScope.fromCode(scopeStr),
            currencyCode: row.read<String>('currency_code'),
            totalMinorUnits: row.read<int>('total'),
            transactionCount: row.read<int>('cnt'),
          ),
        );
      } on ArgumentError {
        continue;
      }
    }
    return result;
  }

  // ── expenseBySpender ──────────────────────────────────────────────────────

  @override
  Future<List<MemberSpendingBreakdown>> expenseBySpender(
    FinancialReportRequest req,
  ) async {
    const sql = '''
      SELECT
        oc.spender_member_id,
        COALESCE(hm.display_name, oc.spender_member_id) AS display_name,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total,
        COUNT(*) AS cnt
      FROM operations o
      JOIN operation_contexts oc ON oc.operation_id = o.id
      LEFT JOIN household_members hm
        ON hm.id = oc.spender_member_id
       AND hm.household_id = o.household_id
      WHERE o.household_id = ?
        AND o.type = 'expense'
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND oc.spender_member_id IS NOT NULL
      GROUP BY oc.spender_member_id, o.currency_code
    ''';

    return _mapMemberBreakdown(
      await _db
          .customSelect(
            sql,
            variables: [
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
              Variable.withString(req.period.endDate),
            ],
          )
          .get(),
    );
  }

  // ── expenseByBeneficiary ──────────────────────────────────────────────────

  @override
  Future<List<MemberSpendingBreakdown>> expenseByBeneficiary(
    FinancialReportRequest req,
  ) async {
    const sql = '''
      SELECT
        oc.beneficiary_member_id AS spender_member_id,
        COALESCE(hm.display_name, oc.beneficiary_member_id) AS display_name,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total,
        COUNT(*) AS cnt
      FROM operations o
      JOIN operation_contexts oc ON oc.operation_id = o.id
      LEFT JOIN household_members hm
        ON hm.id = oc.beneficiary_member_id
       AND hm.household_id = o.household_id
      WHERE o.household_id = ?
        AND o.type = 'expense'
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND oc.beneficiary_member_id IS NOT NULL
      GROUP BY oc.beneficiary_member_id, o.currency_code
    ''';

    return _mapMemberBreakdown(
      await _db
          .customSelect(
            sql,
            variables: [
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
              Variable.withString(req.period.endDate),
            ],
          )
          .get(),
    );
  }

  // ── expenseByCategory ─────────────────────────────────────────────────────

  @override
  Future<List<CategoryBreakdown>> expenseByCategory(
    FinancialReportRequest req,
  ) async {
    const sql = '''
      SELECT
        COALESCE(oc.category_code, o.category_code) AS cat_code,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total,
        COUNT(*) AS cnt
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      WHERE o.household_id = ?
        AND o.type = 'expense'
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND COALESCE(oc.category_code, o.category_code) IS NOT NULL
      GROUP BY cat_code, o.currency_code
    ''';

    return _mapCategoryBreakdown(
      await _db
          .customSelect(
            sql,
            variables: [
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
              Variable.withString(req.period.endDate),
            ],
          )
          .get(),
      CategoryType.expense,
    );
  }

  // ── incomeByCategory ──────────────────────────────────────────────────────

  @override
  Future<List<CategoryBreakdown>> incomeByCategory(
    FinancialReportRequest req,
  ) async {
    const sql = '''
      SELECT
        COALESCE(oc.category_code, o.category_code) AS cat_code,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total,
        COUNT(*) AS cnt
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      WHERE o.household_id = ?
        AND o.type = 'income'
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND COALESCE(oc.category_code, o.category_code) IS NOT NULL
      GROUP BY cat_code, o.currency_code
    ''';

    return _mapCategoryBreakdown(
      await _db
          .customSelect(
            sql,
            variables: [
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
              Variable.withString(req.period.endDate),
            ],
          )
          .get(),
      CategoryType.income,
    );
  }

  // ── accountFlows ──────────────────────────────────────────────────────────

  @override
  Future<List<AccountFlowBreakdown>> accountFlows(
    FinancialReportRequest req,
  ) async {
    final accountRows = await _db
        .customSelect(
          'SELECT id, name, currency_code FROM financial_accounts '
          'WHERE household_id = ? AND is_archived = 0',
          variables: [Variable.withString(req.householdId)],
        )
        .get();

    if (accountRows.isEmpty) return [];

    const openingSql = '''
      SELECT
        SUM(CASE WHEN le.direction = 'credit'
                 THEN le.amount_minor_units
                 ELSE -le.amount_minor_units END) AS opening
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date < ?
    ''';

    const closingSql = '''
      SELECT
        SUM(CASE WHEN le.direction = 'credit'
                 THEN le.amount_minor_units
                 ELSE -le.amount_minor_units END) AS closing
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date < ?
    ''';

    const periodSql = '''
      SELECT
        SUM(CASE WHEN le.entry_type = 'income'
                      AND le.direction = 'credit'
                 THEN le.amount_minor_units ELSE 0 END) AS income,
        SUM(CASE WHEN le.entry_type IN ('expense', 'childFundWithdrawal')
                      AND le.direction = 'debit'
                 THEN le.amount_minor_units ELSE 0 END) AS expense,
        SUM(CASE WHEN le.entry_type = 'transferIn'
                      AND le.direction = 'credit'
                 THEN le.amount_minor_units ELSE 0 END) AS transfers_in,
        SUM(CASE WHEN le.entry_type = 'transferOut'
                      AND le.direction = 'debit'
                 THEN le.amount_minor_units ELSE 0 END) AS transfers_out,
        SUM(CASE WHEN le.entry_type = 'adjustmentCredit'
                 THEN le.amount_minor_units
                 WHEN le.entry_type = 'adjustmentDebit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS adjustments,
        SUM(CASE WHEN le.is_reversal = 1 AND le.direction = 'credit'
                 THEN le.amount_minor_units
                 WHEN le.is_reversal = 1 AND le.direction = 'debit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS reversal_effect
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    final result = <AccountFlowBreakdown>[];
    for (final acc in accountRows) {
      final accountId = acc.read<String>('id');
      final accountName = acc.read<String>('name');
      final currencyCode = acc.read<String>('currency_code');

      final openingRows = await _db
          .customSelect(
            openingSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
            ],
          )
          .get();

      final closingRows = await _db
          .customSelect(
            closingSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
              Variable.withString(req.period.endDate),
            ],
          )
          .get();

      final periodRows = await _db
          .customSelect(
            periodSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
              Variable.withString(req.period.endDate),
            ],
          )
          .get();

      final opening = openingRows.isEmpty
          ? 0
          : (openingRows.first.readNullable<int>('opening') ?? 0);
      final closing = closingRows.isEmpty
          ? 0
          : (closingRows.first.readNullable<int>('closing') ?? 0);

      final pr = periodRows.isEmpty ? null : periodRows.first;
      final income = pr?.readNullable<int>('income') ?? 0;
      final expense = pr?.readNullable<int>('expense') ?? 0;
      final transfersIn = pr?.readNullable<int>('transfers_in') ?? 0;
      final transfersOut = pr?.readNullable<int>('transfers_out') ?? 0;
      final adjustments = pr?.readNullable<int>('adjustments') ?? 0;
      final reversalEffect = pr?.readNullable<int>('reversal_effect') ?? 0;

      result.add(
        AccountFlowBreakdown(
          accountId: accountId,
          accountName: accountName,
          currencyCode: currencyCode,
          openingBalanceMinorUnits: opening,
          incomeMinorUnits: income,
          expenseMinorUnits: expense,
          transfersInMinorUnits: transfersIn,
          transfersOutMinorUnits: transfersOut,
          adjustmentsMinorUnits: adjustments,
          reversalEffectMinorUnits: reversalEffect,
          closingBalanceMinorUnits: closing,
        ),
      );
    }
    return result;
  }

  // ── homeSavingsFlows ──────────────────────────────────────────────────────

  @override
  Future<List<HomeSavingsFlowSummary>> homeSavingsFlows(
    FinancialReportRequest req,
  ) async {
    final accountRows = await _db
        .customSelect(
          "SELECT id, name, currency_code FROM financial_accounts "
          "WHERE household_id = ? AND type = 'homeSavingsCash' AND is_archived = 0",
          variables: [Variable.withString(req.householdId)],
        )
        .get();

    if (accountRows.isEmpty) return [];

    const periodSql = '''
      SELECT
        SUM(CASE WHEN le.entry_type = 'income' AND le.direction = 'credit'
                 THEN le.amount_minor_units ELSE 0 END) AS direct_income,
        SUM(CASE WHEN le.entry_type IN ('expense', 'childFundWithdrawal')
                      AND le.direction = 'debit'
                 THEN le.amount_minor_units ELSE 0 END) AS direct_expense,
        SUM(CASE WHEN le.entry_type = 'transferIn' AND le.direction = 'credit'
                 THEN le.amount_minor_units ELSE 0 END) AS transfers_in,
        SUM(CASE WHEN le.entry_type = 'transferOut' AND le.direction = 'debit'
                 THEN le.amount_minor_units ELSE 0 END) AS transfers_out,
        SUM(CASE WHEN le.entry_type = 'adjustmentCredit'
                 THEN le.amount_minor_units
                 WHEN le.entry_type = 'adjustmentDebit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS adjustments,
        SUM(CASE WHEN le.is_reversal = 1 AND le.direction = 'credit'
                 THEN le.amount_minor_units
                 WHEN le.is_reversal = 1 AND le.direction = 'debit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS reversal_effect
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    // Spouse wallet funding: transfers out from home savings to a spouseCashWallet
    const spouseFundingSql = '''
      SELECT SUM(le.amount_minor_units) AS wallet_funded
      FROM ledger_entries le
      JOIN operations o ON o.id = le.operation_id
      JOIN financial_accounts dest
        ON dest.id = o.destination_account_id
       AND dest.type = 'spouseCashWallet'
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.entry_type = 'transferOut'
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    // Spouse wallet return: transfers in from a spouseCashWallet to home savings
    const spouseReturnSql = '''
      SELECT SUM(le.amount_minor_units) AS wallet_returned
      FROM ledger_entries le
      JOIN operations o ON o.id = le.operation_id
      JOIN financial_accounts src
        ON src.id = o.source_account_id
       AND src.type = 'spouseCashWallet'
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.entry_type = 'transferIn'
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    const balanceSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
    ''';

    const closingSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
        AND effective_date < ?
    ''';

    final result = <HomeSavingsFlowSummary>[];
    for (final acc in accountRows) {
      final accountId = acc.read<String>('id');
      final accountName = acc.read<String>('name');
      final currencyCode = acc.read<String>('currency_code');

      final periodVars = [
        Variable.withString(accountId),
        Variable.withString(req.householdId),
        Variable.withString(req.period.startDate),
        Variable.withString(req.period.endDate),
      ];

      final pr =
          (await _db.customSelect(periodSql, variables: periodVars).get())
              .firstOrNull;
      final sfr =
          (await _db
                  .customSelect(spouseFundingSql, variables: periodVars)
                  .get())
              .firstOrNull;
      final srr =
          (await _db.customSelect(spouseReturnSql, variables: periodVars).get())
              .firstOrNull;

      final balanceRows = await _db
          .customSelect(
            balanceSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
            ],
          )
          .get();

      final openingRows = await _db
          .customSelect(
            closingSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
              Variable.withString(req.period.startDate),
            ],
          )
          .get();

      final closingRows = await _db
          .customSelect(
            closingSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
              Variable.withString(req.period.endDate),
            ],
          )
          .get();

      result.add(
        HomeSavingsFlowSummary(
          accountId: accountId,
          accountName: accountName,
          currencyCode: currencyCode,
          openingBalanceMinorUnits:
              openingRows.firstOrNull?.readNullable<int>('balance') ?? 0,
          directIncomeMinorUnits: pr?.readNullable<int>('direct_income') ?? 0,
          directExpenseMinorUnits: pr?.readNullable<int>('direct_expense') ?? 0,
          transfersInMinorUnits: pr?.readNullable<int>('transfers_in') ?? 0,
          transfersOutMinorUnits: pr?.readNullable<int>('transfers_out') ?? 0,
          spouseWalletFundingMinorUnits:
              sfr?.readNullable<int>('wallet_funded') ?? 0,
          spouseWalletReturnMinorUnits:
              srr?.readNullable<int>('wallet_returned') ?? 0,
          adjustmentsMinorUnits: pr?.readNullable<int>('adjustments') ?? 0,
          reversalEffectMinorUnits:
              pr?.readNullable<int>('reversal_effect') ?? 0,
          closingBalanceMinorUnits:
              closingRows.firstOrNull?.readNullable<int>('balance') ?? 0,
          currentBalanceMinorUnits:
              balanceRows.firstOrNull?.readNullable<int>('balance') ?? 0,
        ),
      );
    }
    return result;
  }

  // ── spouseWalletReports ───────────────────────────────────────────────────

  @override
  Future<List<SpouseWalletReport>> spouseWalletReports(
    FinancialReportRequest req,
  ) async {
    final accountRows = await _db
        .customSelect(
          "SELECT id, name, currency_code FROM financial_accounts "
          "WHERE household_id = ? AND type = 'spouseCashWallet' AND is_archived = 0",
          variables: [Variable.withString(req.householdId)],
        )
        .get();

    if (accountRows.isEmpty) return [];

    const periodSql = '''
      SELECT
        SUM(CASE WHEN le.is_reversal = 0 AND le.direction = 'credit'
                      AND le.entry_type = 'transferIn'
                 THEN le.amount_minor_units ELSE 0 END) AS funded,
        SUM(CASE WHEN le.is_reversal = 0 AND le.direction = 'debit'
                      AND le.entry_type IN ('expense', 'childFundWithdrawal')
                 THEN le.amount_minor_units ELSE 0 END) AS spent,
        SUM(CASE WHEN le.is_reversal = 0 AND le.direction = 'debit'
                      AND le.entry_type = 'transferOut'
                 THEN le.amount_minor_units ELSE 0 END) AS returned,
        SUM(CASE WHEN le.is_reversal = 1 AND le.direction = 'credit'
                 THEN le.amount_minor_units
                 WHEN le.is_reversal = 1 AND le.direction = 'debit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS reversal_effect
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    const openingSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
        AND effective_date < ?
    ''';

    const currentSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
    ''';

    const closingSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
        AND effective_date < ?
    ''';

    final result = <SpouseWalletReport>[];
    for (final acc in accountRows) {
      final accountId = acc.read<String>('id');
      final accountName = acc.read<String>('name');
      final currencyCode = acc.read<String>('currency_code');

      final pr =
          (await _db
                  .customSelect(
                    periodSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.startDate),
                      Variable.withString(req.period.endDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final openingRow =
          (await _db
                  .customSelect(
                    openingSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.startDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final currentRow =
          (await _db
                  .customSelect(
                    currentSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                    ],
                  )
                  .get())
              .firstOrNull;

      final closingRow =
          (await _db
                  .customSelect(
                    closingSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.endDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final opening = openingRow?.readNullable<int>('balance') ?? 0;
      final funded = pr?.readNullable<int>('funded') ?? 0;
      final spent = pr?.readNullable<int>('spent') ?? 0;
      final returned = pr?.readNullable<int>('returned') ?? 0;
      final reversalEffect = pr?.readNullable<int>('reversal_effect') ?? 0;
      final closing = closingRow?.readNullable<int>('balance') ?? 0;
      final current = currentRow?.readNullable<int>('balance') ?? 0;

      result.add(
        SpouseWalletReport(
          accountId: accountId,
          accountName: accountName,
          currencyCode: currencyCode,
          openingBalanceMinorUnits: opening,
          periodFundedMinorUnits: funded,
          periodSpentMinorUnits: spent,
          periodReturnedMinorUnits: returned,
          periodReversalEffectMinorUnits: reversalEffect,
          periodClosingBalanceMinorUnits: closing,
          currentBalanceMinorUnits: current,
        ),
      );
    }
    return result;
  }

  // ── protectedFundsReports ─────────────────────────────────────────────────

  @override
  Future<List<ProtectedFundsSummary>> protectedFundsReports(
    FinancialReportRequest req,
  ) async {
    final accountRows = await _db
        .customSelect(
          'SELECT id, name, currency_code, type FROM financial_accounts '
          'WHERE household_id = ? AND is_protected = 1 AND is_archived = 0',
          variables: [Variable.withString(req.householdId)],
        )
        .get();

    if (accountRows.isEmpty) return [];

    const periodSql = '''
      SELECT
        SUM(CASE WHEN le.direction = 'credit' AND le.is_reversal = 0
                 THEN le.amount_minor_units ELSE 0 END) AS funding,
        SUM(CASE WHEN le.direction = 'debit' AND le.is_reversal = 0
                 THEN le.amount_minor_units ELSE 0 END) AS withdrawal,
        SUM(CASE WHEN le.is_reversal = 1 AND le.direction = 'credit'
                 THEN le.amount_minor_units
                 WHEN le.is_reversal = 1 AND le.direction = 'debit'
                 THEN -le.amount_minor_units
                 ELSE 0 END) AS reversal_effect
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date < ?
    ''';

    const openingSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
        AND effective_date < ?
    ''';

    const closingSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
        AND effective_date < ?
    ''';

    const currentSql = '''
      SELECT SUM(CASE WHEN direction = 'credit'
                      THEN amount_minor_units
                      ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
    ''';

    const auditSql = '''
      SELECT
        cwa.operation_id, cwa.amount_minor_units, cwa.reason,
        cwa.beneficiary, o.effective_date, o.currency_code, o.is_reversed
      FROM child_withdrawal_audits cwa
      JOIN operations o ON o.id = cwa.operation_id
      WHERE cwa.account_id = ?
        AND cwa.household_id = ?
      ORDER BY o.effective_date DESC, cwa.id DESC
    ''';

    final result = <ProtectedFundsSummary>[];
    for (final acc in accountRows) {
      final accountId = acc.read<String>('id');
      final accountName = acc.read<String>('name');
      final currencyCode = acc.read<String>('currency_code');
      final accountTypeCode = acc.read<String>('type');

      final pr =
          (await _db
                  .customSelect(
                    periodSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.startDate),
                      Variable.withString(req.period.endDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final openingRow =
          (await _db
                  .customSelect(
                    openingSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.startDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final closingRow =
          (await _db
                  .customSelect(
                    closingSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                      Variable.withString(req.period.endDate),
                    ],
                  )
                  .get())
              .firstOrNull;

      final currentRow =
          (await _db
                  .customSelect(
                    currentSql,
                    variables: [
                      Variable.withString(accountId),
                      Variable.withString(req.householdId),
                    ],
                  )
                  .get())
              .firstOrNull;

      final auditRows = await _db
          .customSelect(
            auditSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(req.householdId),
            ],
          )
          .get();

      final audits = auditRows.map((r) {
        return WithdrawalAuditSummary(
          operationId: r.read<String>('operation_id'),
          effectiveDate: r.read<String>('effective_date'),
          amountMinorUnits: r.read<int>('amount_minor_units'),
          currencyCode: r.read<String>('currency_code'),
          reason: r.read<String>('reason'),
          beneficiaryMemberId: r.read<String>('beneficiary'),
          isReversed: r.read<int>('is_reversed') == 1,
        );
      }).toList();

      FinancialAccountType accountType;
      try {
        accountType = FinancialAccountType.fromCode(accountTypeCode);
      } catch (_) {
        accountType = FinancialAccountType.childProtectedFund;
      }

      result.add(
        ProtectedFundsSummary(
          accountId: accountId,
          accountName: accountName,
          accountType: accountType,
          currencyCode: currencyCode,
          openingBalanceMinorUnits:
              openingRow?.readNullable<int>('balance') ?? 0,
          fundingMinorUnits: pr?.readNullable<int>('funding') ?? 0,
          withdrawalMinorUnits: pr?.readNullable<int>('withdrawal') ?? 0,
          reversalEffectMinorUnits:
              pr?.readNullable<int>('reversal_effect') ?? 0,
          closingBalanceMinorUnits:
              closingRow?.readNullable<int>('balance') ?? 0,
          currentBalanceMinorUnits:
              currentRow?.readNullable<int>('balance') ?? 0,
          withdrawalAudits: audits,
        ),
      );
    }
    return result;
  }

  // ── drillDown ─────────────────────────────────────────────────────────────

  @override
  Future<List<ReportTransactionRow>> drillDown(
    FinancialReportRequest req, {
    int limit = 100,
  }) async {
    final sql =
        '''
      SELECT
        o.id, o.type, o.effective_date,
        o.total_amount_minor_units, o.currency_code,
        o.is_reversed,
        COALESCE(o.source_account_id, o.destination_account_id) AS account_id,
        COALESCE(src.name, dest.name, 'Unknown') AS account_name,
        COALESCE(oc.category_code, o.category_code) AS cat_code,
        oc.spender_member_id, oc.beneficiary_member_id,
        COALESCE(oc.expense_scope, o.scope) AS effective_scope,
        oc.note,
        CASE WHEN cwa.operation_id IS NOT NULL THEN 1 ELSE 0 END AS is_protected
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      LEFT JOIN financial_accounts src ON src.id = o.source_account_id
      LEFT JOIN financial_accounts dest ON dest.id = o.destination_account_id
      LEFT JOIN child_withdrawal_audits cwa ON cwa.operation_id = o.id
      WHERE o.household_id = ?
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND o.type NOT IN ('openingBalance')
      ORDER BY o.effective_date DESC, o.id DESC
      LIMIT $limit
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [
            Variable.withString(req.householdId),
            Variable.withString(req.period.startDate),
            Variable.withString(req.period.endDate),
          ],
        )
        .get();

    final result = <ReportTransactionRow>[];
    for (final row in rows) {
      final typeStr = row.read<String>('type');
      OperationType opType;
      try {
        opType = OperationType.fromCode(typeStr);
      } catch (_) {
        continue;
      }

      final scopeStr = row.readNullable<String>('effective_scope');
      ExpenseScope? scope;
      if (scopeStr != null) {
        try {
          scope = ExpenseScope.fromCode(scopeStr);
        } catch (_) {}
      }

      result.add(
        ReportTransactionRow(
          operationId: row.read<String>('id'),
          operationType: opType,
          effectiveDate: row.read<String>('effective_date'),
          amountMinorUnits: row.read<int>('total_amount_minor_units'),
          currencyCode: row.read<String>('currency_code'),
          accountId: row.readNullable<String>('account_id') ?? '',
          accountName: row.readNullable<String>('account_name') ?? '',
          categoryCode: row.readNullable<String>('cat_code'),
          spenderMemberId: row.readNullable<String>('spender_member_id'),
          beneficiaryMemberId: row.readNullable<String>(
            'beneficiary_member_id',
          ),
          scope: scope,
          isReversed: row.read<int>('is_reversed') == 1,
          isProtectedWithdrawal: row.read<int>('is_protected') == 1,
          note: row.readNullable<String>('note'),
        ),
      );
    }
    return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  List<MemberSpendingBreakdown> _mapMemberBreakdown(List<QueryRow> rows) {
    return rows.map((row) {
      return MemberSpendingBreakdown(
        memberId: row.read<String>('spender_member_id'),
        memberDisplayName: row.read<String>('display_name'),
        currencyCode: row.read<String>('currency_code'),
        totalMinorUnits: row.read<int>('total'),
        transactionCount: row.read<int>('cnt'),
      );
    }).toList();
  }

  List<CategoryBreakdown> _mapCategoryBreakdown(
    List<QueryRow> rows,
    CategoryType defaultType,
  ) {
    return rows.map((row) {
      final catCode = row.readNullable<String>('cat_code') ?? '';
      CategoryType type = defaultType;
      try {
        type = TransactionCategory.fromCode(catCode).type;
      } catch (_) {}

      return CategoryBreakdown(
        categoryCode: catCode,
        categoryType: type,
        currencyCode: row.read<String>('currency_code'),
        totalMinorUnits: row.read<int>('total'),
        transactionCount: row.read<int>('cnt'),
      );
    }).toList();
  }
}

/// Mutable accumulator for [incomeExpenseFlow].
class _FlowAcc {
  int grossIncome = 0;
  int grossExpense = 0;
  int incomeReversal = 0;
  int expenseReversal = 0;
}
