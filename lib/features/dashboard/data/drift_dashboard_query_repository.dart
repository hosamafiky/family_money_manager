import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/dashboard/data/dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Drift-backed implementation of [DashboardQueryRepository].
///
/// All queries are read-only. Uses raw SQL via [AppDatabase.customSelect] for
/// cross-table joins. Balances are derived from ledger entries on every call
/// (no mutable cached balance field per FINANCIAL_MODEL §3).
final class DriftDashboardQueryRepository implements DashboardQueryRepository {
  const DriftDashboardQueryRepository(this._db);

  final AppDatabase _db;

  // ── spendableBalances ──────────────────────────────────────────────────────

  @override
  Future<List<CurrencyAmountSummary>> spendableBalances({required String householdId}) async {
    const sql = '''
      SELECT
        le.currency_code,
        SUM(
          CASE WHEN le.direction = 'credit'
               THEN le.amount_minor_units
               ELSE -le.amount_minor_units END
        ) AS total
      FROM ledger_entries le
      JOIN financial_accounts fa ON fa.id = le.account_id
      WHERE fa.household_id = ?
        AND fa.is_archived = 0
        AND fa.is_spendable = 1
        AND fa.is_protected = 0
        AND le.household_id = ?
      GROUP BY le.currency_code
    ''';

    final rows = await _db.customSelect(sql, variables: [Variable.withString(householdId), Variable.withString(householdId)]).get();

    return rows.map((r) => CurrencyAmountSummary(currencyCode: r.read<String>('currency_code'), totalMinorUnits: r.read<int>('total'))).toList();
  }

  // ── protectedBalances ──────────────────────────────────────────────────────

  @override
  Future<List<CurrencyAmountSummary>> protectedBalances({required String householdId}) async {
    const sql = '''
      SELECT
        le.currency_code,
        SUM(
          CASE WHEN le.direction = 'credit'
               THEN le.amount_minor_units
               ELSE -le.amount_minor_units END
        ) AS total
      FROM ledger_entries le
      JOIN financial_accounts fa ON fa.id = le.account_id
      WHERE fa.household_id = ?
        AND fa.is_archived = 0
        AND fa.is_protected = 1
        AND le.household_id = ?
      GROUP BY le.currency_code
    ''';

    final rows = await _db.customSelect(sql, variables: [Variable.withString(householdId), Variable.withString(householdId)]).get();

    return rows.map((r) => CurrencyAmountSummary(currencyCode: r.read<String>('currency_code'), totalMinorUnits: r.read<int>('total'))).toList();
  }

  // ── periodFlow ─────────────────────────────────────────────────────────────
  //
  // PERIOD-ACTIVITY MODEL (Phase 4B):
  // All income/expense operations in the period are included regardless of
  // is_reversed. Reversal operations (type='reversal') in the period are
  // queried separately and linked back to the original operation type.

  @override
  Future<List<PeriodFlowSummary>> periodFlow({required String householdId, required DashboardPeriod period}) async {
    // Query 1: gross income and expense (no is_reversed filter).
    const grossSql = '''
      SELECT
        currency_code,
        type,
        SUM(total_amount_minor_units) AS subtotal
      FROM operations
      WHERE household_id = ?
        AND effective_date >= ?
        AND effective_date < ?
        AND type IN ('income', 'expense')
      GROUP BY currency_code, type
    ''';

    // Query 2: reversal operations in the period, joined to the original
    // operation to determine whether they cancel income or expense.
    const reversalSql = '''
      SELECT
        rev.currency_code,
        orig.type AS original_type,
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

    final grossRows = await _db
        .customSelect(grossSql, variables: [Variable.withString(householdId), Variable.withString(period.startDate), Variable.withString(period.endDate)])
        .get();

    final reversalRows = await _db
        .customSelect(reversalSql, variables: [Variable.withString(householdId), Variable.withString(period.startDate), Variable.withString(period.endDate)])
        .get();

    final map = <String, _FlowAccumulator>{};

    for (final row in grossRows) {
      final currency = row.read<String>('currency_code');
      final type = row.read<String>('type');
      final subtotal = row.read<int>('subtotal');
      final acc = map.putIfAbsent(currency, _FlowAccumulator.new);
      if (type == OperationType.income.code) {
        acc.grossIncome += subtotal;
      } else if (type == OperationType.expense.code) {
        acc.grossExpense += subtotal;
      }
    }

    for (final row in reversalRows) {
      final currency = row.read<String>('currency_code');
      final originalType = row.read<String>('original_type');
      final reversalAmount = row.read<int>('reversal_amount');
      final acc = map.putIfAbsent(currency, _FlowAccumulator.new);
      if (originalType == OperationType.income.code) {
        acc.incomeReversal += reversalAmount;
      } else if (originalType == OperationType.expense.code) {
        acc.expenseReversal += reversalAmount;
      }
    }

    return map.entries
        .map(
          (e) => PeriodFlowSummary(
            currencyCode: e.key,
            grossIncomeMinorUnits: e.value.grossIncome,
            grossExpenseMinorUnits: e.value.grossExpense,
            incomeReversalMinorUnits: e.value.incomeReversal,
            expenseReversalMinorUnits: e.value.expenseReversal,
          ),
        )
        .toList();
  }

  // ── expensesByScope ────────────────────────────────────────────────────────

  @override
  Future<List<ExpenseScopeSummary>> expensesByScope({required String householdId, required DashboardPeriod period}) async {
    // Prefer expense_scope from operation_contexts; fall back to operations.scope
    const sql = '''
      SELECT
        COALESCE(oc.expense_scope, o.scope) AS effective_scope,
        o.currency_code,
        SUM(o.total_amount_minor_units) AS total
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      WHERE o.household_id = ?
        AND o.effective_date >= ?
        AND o.effective_date < ?
        AND o.type = 'expense'
        AND o.is_reversed = 0
        AND COALESCE(oc.expense_scope, o.scope) IS NOT NULL
      GROUP BY effective_scope, o.currency_code
    ''';

    final rows = await _db
        .customSelect(sql, variables: [Variable.withString(householdId), Variable.withString(period.startDate), Variable.withString(period.endDate)])
        .get();

    final result = <ExpenseScopeSummary>[];
    for (final row in rows) {
      final scopeStr = row.readNullable<String>('effective_scope');
      if (scopeStr == null) continue;
      try {
        final scope = ExpenseScope.fromCode(scopeStr);
        result.add(ExpenseScopeSummary(scope: scope, currencyCode: row.read<String>('currency_code'), totalMinorUnits: row.read<int>('total')));
      } on ArgumentError {
        // Unknown scope code — skip rather than crash
        continue;
      }
    }
    return result;
  }

  // ── spouseWalletSummaries ──────────────────────────────────────────────────

  @override
  Future<List<SpouseWalletDashboardSummary>> spouseWalletSummaries({required String householdId, required DashboardPeriod period}) async {
    // Find all spouseCashWallet accounts in the household (including archived,
    // to surface all wallets that were ever active; filter is_archived in UI).
    final accountRows = await _db
        .customSelect(
          "SELECT id, name, currency_code FROM financial_accounts "
          "WHERE household_id = ? AND type = 'spouseCashWallet' AND is_archived = 0",
          variables: [Variable.withString(householdId)],
        )
        .get();

    if (accountRows.isEmpty) return [];

    const periodSql = '''
      SELECT
        SUM(CASE WHEN le.direction = 'credit'
                      AND le.entry_type = 'transferIn'
                 THEN le.amount_minor_units ELSE 0 END) AS funded,
        SUM(CASE WHEN le.direction = 'debit'
                      AND le.entry_type IN ('expense', 'childFundWithdrawal')
                 THEN le.amount_minor_units ELSE 0 END) AS spent,
        SUM(CASE WHEN le.direction = 'debit'
                      AND le.entry_type = 'transferOut'
                 THEN le.amount_minor_units ELSE 0 END) AS returned
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date < ?
        AND le.is_reversal = 0
    ''';

    const balanceSql = '''
      SELECT
        SUM(CASE WHEN direction = 'credit'
                 THEN amount_minor_units
                 ELSE -amount_minor_units END) AS balance
      FROM ledger_entries
      WHERE account_id = ? AND household_id = ?
    ''';

    final result = <SpouseWalletDashboardSummary>[];
    for (final acc in accountRows) {
      final accountId = acc.read<String>('id');
      final accountName = acc.read<String>('name');
      final currencyCode = acc.read<String>('currency_code');

      final periodRows = await _db
          .customSelect(
            periodSql,
            variables: [
              Variable.withString(accountId),
              Variable.withString(householdId),
              Variable.withString(period.startDate),
              Variable.withString(period.endDate),
            ],
          )
          .get();

      final balanceRows = await _db.customSelect(balanceSql, variables: [Variable.withString(accountId), Variable.withString(householdId)]).get();

      final periodRow = periodRows.isEmpty ? null : periodRows.first;
      final funded = periodRow?.read<int?>('funded') ?? 0;
      final spent = periodRow?.read<int?>('spent') ?? 0;
      final returned = periodRow?.read<int?>('returned') ?? 0;

      final balanceRow = balanceRows.isEmpty ? null : balanceRows.first;
      final balance = balanceRow?.read<int?>('balance') ?? 0;

      result.add(
        SpouseWalletDashboardSummary(
          accountId: accountId,
          accountName: accountName,
          currencyCode: currencyCode,
          periodFundedMinorUnits: funded,
          periodSpentMinorUnits: spent,
          periodReturnedMinorUnits: returned,
          currentBalanceMinorUnits: balance,
        ),
      );
    }
    return result;
  }

  // ── recentActivity ─────────────────────────────────────────────────────────

  @override
  Future<List<TransactionSummary>> recentActivity({required String householdId, int limit = 20}) async {
    final sql =
        '''
      SELECT
        o.id, o.household_id, o.type, o.effective_date, o.recorded_at,
        o.description, o.category_code, o.scope, o.spender_role,
        o.beneficiary_role, o.source_account_id, o.destination_account_id,
        o.total_amount_minor_units, o.currency_code, o.is_recurring,
        o.recurring_rule_id, o.tags, o.receipt_path, o.is_reversed,
        o.reversed_by, o.created_by, o.created_at, o.updated_at,
        o.sync_status, o.idempotency_key,
        oc.spender_member_id, oc.beneficiary_member_id,
        oc.expense_scope AS ctx_scope,
        oc.is_recurring AS ctx_is_recurring,
        oc.note AS ctx_note
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      WHERE o.household_id = ?
      ORDER BY o.effective_date DESC, o.recorded_at DESC, o.id DESC
      LIMIT $limit
    ''';

    final rows = await _db.customSelect(sql, variables: [Variable.withString(householdId)]).get();

    return rows.map(_rowToTransactionSummary).toList();
  }

  // ── Private mappers ────────────────────────────────────────────────────────

  TransactionSummary _rowToTransactionSummary(QueryRow row) {
    final scopeStr = row.readNullable<String>('scope');
    final ctxScopeStr = row.readNullable<String>('ctx_scope');
    final effectiveScopeStr = ctxScopeStr ?? scopeStr;

    final tagsStr = row.readNullable<String>('tags');
    final tags = tagsStr != null ? tagsStr.split(',').where((s) => s.isNotEmpty).toList() : <String>[];

    final op = Operation(
      id: row.read<String>('id'),
      householdId: row.read<String>('household_id'),
      type: OperationType.fromCode(row.read<String>('type')),
      effectiveDate: row.read<String>('effective_date'),
      recordedAt: DateTime.parse(row.read<String>('recorded_at')).toUtc(),
      description: row.readNullable<String>('description'),
      categoryCode: row.readNullable<String>('category_code'),
      scope: scopeStr != null ? ExpenseScope.fromCode(scopeStr) : null,
      spenderRole: null,
      beneficiaryRole: null,
      sourceAccountId: row.readNullable<String>('source_account_id'),
      destinationAccountId: row.readNullable<String>('destination_account_id'),
      totalAmountMinorUnits: row.read<int>('total_amount_minor_units'),
      currencyCode: row.read<String>('currency_code'),
      isRecurring: row.read<bool>('is_recurring'),
      recurringRuleId: row.readNullable<String>('recurring_rule_id'),
      tags: tags,
      receiptPath: row.readNullable<String>('receipt_path'),
      isReversed: row.read<bool>('is_reversed'),
      reversedBy: row.readNullable<String>('reversed_by'),
      createdBy: row.read<String>('created_by'),
      createdAt: row.read<String>('created_at'),
      updatedAt: row.read<String>('updated_at'),
    );

    return TransactionSummary(
      operation: op,
      categoryCode: row.readNullable<String>('category_code'),
      spenderMemberId: row.readNullable<String>('spender_member_id'),
      beneficiaryMemberId: row.readNullable<String>('beneficiary_member_id'),
      scope: effectiveScopeStr != null ? ExpenseScope.fromCode(effectiveScopeStr) : null,
      isRecurring: (row.readNullable<int>('ctx_is_recurring') ?? 0) == 1 || row.read<bool>('is_recurring'),
      note: row.readNullable<String>('ctx_note') ?? row.readNullable<String>('description'),
    );
  }
}

/// Mutable accumulator used to aggregate period flow in [periodFlow].
class _FlowAccumulator {
  int grossIncome = 0;
  int grossExpense = 0;
  int incomeReversal = 0;
  int expenseReversal = 0;
}
