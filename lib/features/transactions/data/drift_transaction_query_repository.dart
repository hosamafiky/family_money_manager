import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Drift-backed implementation of [TransactionQueryRepository].
///
/// Uses raw `customSelect` queries for cross-table joins (operations ⟕ operation_contexts).
/// All queries are read-only.
final class DriftTransactionQueryRepository implements TransactionQueryRepository {
  const DriftTransactionQueryRepository(this._db);

  final AppDatabase _db;

  // ── recentOperations ───────────────────────────────────────────────────────

  @override
  Future<List<TransactionSummary>> recentOperations({
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    final whereClause = StringBuffer('o.household_id = ?');
    final args = <Object?>[householdId];

    _applyFilterClauses(whereClause, args, filter, tablePrefix: 'o', contextPrefix: 'oc');

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
      WHERE $whereClause
      ORDER BY o.effective_date DESC, o.recorded_at DESC, o.id DESC
      LIMIT ${filter.pageSize}
    ''';

    final rows = await _db.customSelect(sql, variables: _toVariables(args)).get();
    return rows.map(_rowToSummary).toList();
  }

  // ── operationsForAccount ───────────────────────────────────────────────────

  @override
  Future<List<TransactionSummary>> operationsForAccount({
    required String accountId,
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    final whereClause = StringBuffer(
      'o.household_id = ? AND (o.source_account_id = ? OR o.destination_account_id = ?)',
    );
    final args = <Object?>[householdId, accountId, accountId];

    _applyFilterClauses(whereClause, args, filter, tablePrefix: 'o', contextPrefix: 'oc');

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
      WHERE $whereClause
      ORDER BY o.effective_date DESC, o.recorded_at DESC, o.id DESC
      LIMIT ${filter.pageSize}
    ''';

    final rows = await _db.customSelect(sql, variables: _toVariables(args)).get();
    return rows.map(_rowToSummary).toList();
  }

  // ── operationDetail ────────────────────────────────────────────────────────

  @override
  Future<TransactionSummary?> operationDetail({
    required String operationId,
    required String householdId,
  }) async {
    const sql = '''
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
      WHERE o.id = ? AND o.household_id = ?
      LIMIT 1
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [Variable.withString(operationId), Variable.withString(householdId)],
        )
        .get();

    return rows.isEmpty ? null : _rowToSummary(rows.first);
  }

  // ── spouseWalletSummary ────────────────────────────────────────────────────

  @override
  Future<SpouseWalletSummary> spouseWalletSummary({
    required String spouseAccountId,
    required String householdId,
    required String fromDate,
    required String toDate,
  }) async {
    // Determine the currency of the account.
    final accountRows = await _db
        .customSelect(
          'SELECT currency_code FROM financial_accounts WHERE id = ? AND household_id = ? LIMIT 1',
          variables: [Variable.withString(spouseAccountId), Variable.withString(householdId)],
        )
        .get();
    final currencyCode = accountRows.isEmpty
        ? 'EGP'
        : accountRows.first.read<String>('currency_code');

    const sql = '''
      SELECT
        SUM(CASE WHEN le.direction = 'credit' AND le.entry_type = 'transferIn'
                 THEN le.amount_minor_units ELSE 0 END) AS total_funded,
        SUM(CASE WHEN le.direction = 'debit'
                      AND le.entry_type IN ('expense', 'childFundWithdrawal')
                 THEN le.amount_minor_units ELSE 0 END) AS total_spent,
        SUM(CASE WHEN le.direction = 'debit' AND le.entry_type = 'transferOut'
                 THEN le.amount_minor_units ELSE 0 END) AS total_returned
      FROM ledger_entries le
      WHERE le.account_id = ?
        AND le.household_id = ?
        AND le.effective_date >= ?
        AND le.effective_date <= ?
        AND le.is_reversal = 0
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [
            Variable.withString(spouseAccountId),
            Variable.withString(householdId),
            Variable.withString(fromDate),
            Variable.withString(toDate),
          ],
        )
        .get();

    final row = rows.isEmpty ? null : rows.first;
    final totalFunded = row?.read<int?>('total_funded') ?? 0;
    final totalSpent = row?.read<int?>('total_spent') ?? 0;
    final totalReturned = row?.read<int?>('total_returned') ?? 0;

    return SpouseWalletSummary(
      totalFunded: totalFunded,
      totalSpent: totalSpent,
      totalReturned: totalReturned,
      derivedBalance: totalFunded - totalSpent - totalReturned,
      currencyCode: currencyCode,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _applyFilterClauses(
    StringBuffer where,
    List<Object?> args,
    TransactionFilter filter, {
    required String tablePrefix,
    required String contextPrefix,
  }) {
    if (filter.operationType != null) {
      where.write(' AND $tablePrefix.type = ?');
      args.add(filter.operationType!.code);
    }
    if (filter.categoryCode != null) {
      where.write(' AND $tablePrefix.category_code = ?');
      args.add(filter.categoryCode);
    }
    if (filter.spenderMemberId != null) {
      where.write(' AND $contextPrefix.spender_member_id = ?');
      args.add(filter.spenderMemberId);
    }
    if (filter.beneficiaryMemberId != null) {
      where.write(' AND $contextPrefix.beneficiary_member_id = ?');
      args.add(filter.beneficiaryMemberId);
    }
    if (filter.scope != null) {
      where.write(' AND $tablePrefix.scope = ?');
      args.add(filter.scope!.code);
    }
    if (filter.fromDate != null) {
      where.write(' AND $tablePrefix.effective_date >= ?');
      args.add(filter.fromDate);
    }
    if (filter.toDate != null) {
      where.write(' AND $tablePrefix.effective_date <= ?');
      args.add(filter.toDate);
    }
  }

  List<Variable<Object>> _toVariables(List<Object?> args) {
    return args.map((a) {
      if (a is String) return Variable.withString(a);
      if (a is int) return Variable.withInt(a);
      if (a is bool) return Variable.withBool(a);
      return Variable.withString(a?.toString() ?? '');
    }).toList();
  }

  TransactionSummary _rowToSummary(QueryRow row) {
    final scopeStr = row.readNullable<String>('scope');
    final ctxScopeStr = row.readNullable<String>('ctx_scope');
    final effectiveScopeStr = ctxScopeStr ?? scopeStr;

    final tagsStr = row.readNullable<String>('tags');
    final tags = tagsStr != null
        ? tagsStr.split(',').where((s) => s.isNotEmpty).toList()
        : <String>[];

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
      isRecurring:
          (row.readNullable<int>('ctx_is_recurring') ?? 0) == 1 || row.read<bool>('is_recurring'),
      note: row.readNullable<String>('ctx_note') ?? row.readNullable<String>('description'),
    );
  }
}
