import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_detail.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Drift-backed implementation of [TransactionQueryRepository].
///
/// Uses raw `customSelect` queries for cross-table joins (operations ⟕ operation_contexts).
/// All queries are read-only.
final class DriftTransactionQueryRepository
    implements TransactionQueryRepository {
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

    _applyFilterClauses(
      whereClause,
      args,
      filter,
      tablePrefix: 'o',
      contextPrefix: 'oc',
    );

    final sql =
        '''
      SELECT
        o.id, o.household_id, o.type, o.effective_date, o.recorded_at,
        o.description, o.category_code, o.scope, o.spender_role,
        o.beneficiary_role, o.source_account_id, o.destination_account_id,
        o.total_amount_minor_units, o.currency_code, o.is_recurring,
        o.recurring_rule_id, o.tags, o.receipt_path, o.is_reversed,
        o.reversed_by, o.reversal_reason, o.created_by, o.created_at,
        o.updated_at,
        o.sync_status, o.idempotency_key,
        oc.spender_member_id, oc.beneficiary_member_id,
        oc.expense_scope AS ctx_scope,
        oc.is_recurring AS ctx_is_recurring,
        oc.note AS ctx_note,
        src.name AS source_account_name,
        dst.name AS destination_account_name,
        spender.display_name AS spender_name,
        beneficiary.display_name AS beneficiary_name,
        author.display_name AS created_by_name
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      -- Names, resolved once here rather than looked up per rendered row.
      -- Every join is on a primary key and scoped to the same household, so
      -- a row can never pick up a name from another family's data.
      LEFT JOIN financial_accounts src
        ON src.id = o.source_account_id AND src.household_id = o.household_id
      LEFT JOIN financial_accounts dst
        ON dst.id = o.destination_account_id
       AND dst.household_id = o.household_id
      LEFT JOIN household_members spender
        ON spender.id = oc.spender_member_id
       AND spender.household_id = o.household_id
      LEFT JOIN household_members beneficiary
        ON beneficiary.id = oc.beneficiary_member_id
       AND beneficiary.household_id = o.household_id
      LEFT JOIN household_members author
        ON author.id = o.created_by AND author.household_id = o.household_id
      WHERE $whereClause
      ORDER BY o.effective_date DESC, o.recorded_at DESC, o.id DESC
      LIMIT ${filter.pageSize}
    ''';

    final rows = await _db
        .customSelect(sql, variables: _toVariables(args))
        .get();
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

    _applyFilterClauses(
      whereClause,
      args,
      filter,
      tablePrefix: 'o',
      contextPrefix: 'oc',
    );

    final sql =
        '''
      SELECT
        o.id, o.household_id, o.type, o.effective_date, o.recorded_at,
        o.description, o.category_code, o.scope, o.spender_role,
        o.beneficiary_role, o.source_account_id, o.destination_account_id,
        o.total_amount_minor_units, o.currency_code, o.is_recurring,
        o.recurring_rule_id, o.tags, o.receipt_path, o.is_reversed,
        o.reversed_by, o.reversal_reason, o.created_by, o.created_at,
        o.updated_at,
        o.sync_status, o.idempotency_key,
        oc.spender_member_id, oc.beneficiary_member_id,
        oc.expense_scope AS ctx_scope,
        oc.is_recurring AS ctx_is_recurring,
        oc.note AS ctx_note,
        src.name AS source_account_name,
        dst.name AS destination_account_name,
        spender.display_name AS spender_name,
        beneficiary.display_name AS beneficiary_name,
        author.display_name AS created_by_name
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      -- Names, resolved once here rather than looked up per rendered row.
      -- Every join is on a primary key and scoped to the same household, so
      -- a row can never pick up a name from another family's data.
      LEFT JOIN financial_accounts src
        ON src.id = o.source_account_id AND src.household_id = o.household_id
      LEFT JOIN financial_accounts dst
        ON dst.id = o.destination_account_id
       AND dst.household_id = o.household_id
      LEFT JOIN household_members spender
        ON spender.id = oc.spender_member_id
       AND spender.household_id = o.household_id
      LEFT JOIN household_members beneficiary
        ON beneficiary.id = oc.beneficiary_member_id
       AND beneficiary.household_id = o.household_id
      LEFT JOIN household_members author
        ON author.id = o.created_by AND author.household_id = o.household_id
      WHERE $whereClause
      ORDER BY o.effective_date DESC, o.recorded_at DESC, o.id DESC
      LIMIT ${filter.pageSize}
    ''';

    final rows = await _db
        .customSelect(sql, variables: _toVariables(args))
        .get();
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
        o.reversed_by, o.reversal_reason, o.created_by, o.created_at,
        o.updated_at,
        o.sync_status, o.idempotency_key,
        oc.spender_member_id, oc.beneficiary_member_id,
        oc.expense_scope AS ctx_scope,
        oc.is_recurring AS ctx_is_recurring,
        oc.note AS ctx_note,
        src.name AS source_account_name,
        dst.name AS destination_account_name,
        spender.display_name AS spender_name,
        beneficiary.display_name AS beneficiary_name,
        author.display_name AS created_by_name
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      -- Names, resolved once here rather than looked up per rendered row.
      -- Every join is on a primary key and scoped to the same household, so
      -- a row can never pick up a name from another family's data.
      LEFT JOIN financial_accounts src
        ON src.id = o.source_account_id AND src.household_id = o.household_id
      LEFT JOIN financial_accounts dst
        ON dst.id = o.destination_account_id
       AND dst.household_id = o.household_id
      LEFT JOIN household_members spender
        ON spender.id = oc.spender_member_id
       AND spender.household_id = o.household_id
      LEFT JOIN household_members beneficiary
        ON beneficiary.id = oc.beneficiary_member_id
       AND beneficiary.household_id = o.household_id
      LEFT JOIN household_members author
        ON author.id = o.created_by AND author.household_id = o.household_id
      WHERE o.id = ? AND o.household_id = ?
      LIMIT 1
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [
            Variable.withString(operationId),
            Variable.withString(householdId),
          ],
        )
        .get();

    return rows.isEmpty ? null : _rowToSummary(rows.first);
  }

  // ── countOperations ────────────────────────────────────────────────────────

  @override
  Future<int> countOperations({
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    final whereClause = StringBuffer('o.household_id = ?');
    final args = <Object?>[householdId];

    _applyFilterClauses(
      whereClause,
      args,
      filter,
      tablePrefix: 'o',
      contextPrefix: 'oc',
    );

    // The same joins as the list, because the filter can restrict on account
    // names. No LIMIT: the point of this query is the total the page size
    // would otherwise hide.
    final rows = await _db.customSelect('''
      SELECT COUNT(*) AS matching_count
      FROM operations o
      LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
      LEFT JOIN financial_accounts src
        ON src.id = o.source_account_id AND src.household_id = o.household_id
      LEFT JOIN financial_accounts dst
        ON dst.id = o.destination_account_id
       AND dst.household_id = o.household_id
      WHERE $whereClause
    ''', variables: _toVariables(args)).get();

    return rows.first.read<int>('matching_count');
  }

  // ── operationDetailWithLedger ──────────────────────────────────────────────

  @override
  Future<TransactionDetail?> operationDetailWithLedger({
    required String operationId,
    required String householdId,
  }) async {
    final summary = await operationDetail(
      operationId: operationId,
      householdId: householdId,
    );
    if (summary == null) return null;

    // Debits before credits, then a stable tiebreak. The double entry reads
    // as a pair, and a pair that reorders between rebuilds is unreadable.
    final entryRows = await _db
        .customSelect(
          '''
      SELECT
        le.id, le.direction, le.account_id, le.amount_minor_units,
        le.currency_code, le.entry_type,
        fa.name AS account_name
      FROM ledger_entries le
      LEFT JOIN financial_accounts fa
        ON fa.id = le.account_id AND fa.household_id = le.household_id
      WHERE le.operation_id = ? AND le.household_id = ?
      ORDER BY CASE le.direction WHEN 'debit' THEN 0 ELSE 1 END, le.id
    ''',
          variables: [
            Variable.withString(operationId),
            Variable.withString(householdId),
          ],
        )
        .get();

    final ledgerLines = entryRows
        .map(
          (row) => OperationLedgerLine(
            entryId: row.read<String>('id'),
            direction: LedgerDirection.fromCode(row.read<String>('direction')),
            accountId: row.read<String>('account_id'),
            // Falls back to the id rather than to blank: a nameless row reads
            // as a rendering bug, an id reads as a missing account.
            accountName:
                row.readNullable<String>('account_name') ??
                row.read<String>('account_id'),
            amountMinorUnits: row.read<int>('amount_minor_units'),
            currencyCode: row.read<String>('currency_code'),
            entryType: LedgerEntryType.fromCode(row.read<String>('entry_type')),
          ),
        )
        .toList();

    return TransactionDetail(
      summary: summary,
      ledgerLines: ledgerLines,
      counterpart: await _counterpart(summary, householdId),
    );
  }

  /// The other half of a reversal pair, from whichever side is being viewed.
  Future<ReversalCounterpart?> _counterpart(
    TransactionSummary summary,
    String householdId,
  ) async {
    final op = summary.operation;

    // Viewing the original: `reversedBy` names the correction directly.
    // Viewing the reversal: nothing points forward, so the original is found
    // by the link the reversal's own row carries back.
    final (counterpartId, isReversingEntry) = switch (op) {
      Operation(reversedBy: final String id) => (id, true),
      Operation(type: OperationType.reversal) => (
        await _originalOf(op.id, householdId),
        false,
      ),
      _ => (null, false),
    };
    if (counterpartId == null) return null;

    final rows = await _db
        .customSelect(
          '''
      SELECT
        o.id, o.effective_date, o.total_amount_minor_units, o.currency_code,
        o.reversal_reason, o.created_by,
        hm.display_name AS author_name
      FROM operations o
      LEFT JOIN household_members hm
        ON hm.id = o.created_by AND hm.household_id = o.household_id
      WHERE o.id = ? AND o.household_id = ?
      LIMIT 1
    ''',
          variables: [
            Variable.withString(counterpartId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (rows.isEmpty) return null;

    final row = rows.first;
    // The reason lives on the reversing entry, so it is read from whichever
    // of the two rows that is.
    final reason = isReversingEntry
        ? row.readNullable<String>('reversal_reason')
        : op.reversalReason;

    return ReversalCounterpart(
      operationId: row.read<String>('id'),
      effectiveDate: row.read<String>('effective_date'),
      totalAmountMinorUnits: row.read<int>('total_amount_minor_units'),
      currencyCode: row.read<String>('currency_code'),
      isReversingEntry: isReversingEntry,
      reason: reason,
      authorName: row.readNullable<String>('author_name'),
    );
  }

  /// The operation a reversal answers, via the entry-level back link.
  ///
  /// `operations` carries no forward pointer from a reversal to its original —
  /// only `ledger_entries.reversal_of_entry_id` does — so the walk is entry →
  /// original entry → its operation.
  Future<String?> _originalOf(String reversalId, String householdId) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT original.operation_id AS original_operation_id
      FROM ledger_entries rev
      JOIN ledger_entries original ON original.id = rev.reversal_of_entry_id
      WHERE rev.operation_id = ? AND rev.household_id = ?
        AND rev.reversal_of_entry_id IS NOT NULL
      LIMIT 1
    ''',
          variables: [
            Variable.withString(reversalId),
            Variable.withString(householdId),
          ],
        )
        .get();
    return rows.isEmpty
        ? null
        : rows.first.read<String>('original_operation_id');
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
          variables: [
            Variable.withString(spouseAccountId),
            Variable.withString(householdId),
          ],
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
    if (filter.accountId case final String accountId) {
      where.write(
        ' AND ($tablePrefix.source_account_id = ?'
        ' OR $tablePrefix.destination_account_id = ?)',
      );
      args
        ..add(accountId)
        ..add(accountId);
    }
    if (filter.amountRange case final TransactionAmountRange range) {
      // The currency is always part of the comparison, never optional: an
      // amount band that spanned currencies would match a USD row against an
      // EGP threshold.
      where.write(' AND $tablePrefix.currency_code = ?');
      args.add(range.currencyCode);
      if (range.minMinorUnits case final int min) {
        where.write(' AND $tablePrefix.total_amount_minor_units >= ?');
        args.add(min);
      }
      if (range.maxMinorUnits case final int max) {
        where.write(' AND $tablePrefix.total_amount_minor_units <= ?');
        args.add(max);
      }
    }
    if (!filter.includeReversed) {
      // Both halves go: the original whose effect was cancelled, and the
      // entry that cancelled it.
      where.write(
        ' AND $tablePrefix.is_reversed = 0 AND $tablePrefix.type != ?',
      );
      args.add(OperationType.reversal.code);
    }
    if (filter.searchQuery?.trim() case final String query
        when query.isNotEmpty) {
      // Description, note and both account names. `LIKE` is case-insensitive
      // for ASCII only in SQLite, which is why the Arabic side matches
      // literally — correct for Arabic, where there is no case to fold.
      const escape = r"ESCAPE '\'";
      where.write(
        ' AND ($tablePrefix.description LIKE ? $escape'
        ' OR $contextPrefix.note LIKE ? $escape'
        ' OR src.name LIKE ? $escape'
        ' OR dst.name LIKE ? $escape)',
      );
      // Escaped so a user typing % or _ searches for those characters rather
      // than turning their query into a wildcard.
      final pattern = '%${_escapeLike(query)}%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }
  }

  /// Escapes SQL `LIKE` metacharacters. Paired with `ESCAPE` below.
  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

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
      reversalReason: row.readNullable<String>('reversal_reason'),
      createdBy: row.read<String>('created_by'),
      createdAt: row.read<String>('created_at'),
      updatedAt: row.read<String>('updated_at'),
    );

    return TransactionSummary(
      operation: op,
      categoryCode: row.readNullable<String>('category_code'),
      spenderMemberId: row.readNullable<String>('spender_member_id'),
      beneficiaryMemberId: row.readNullable<String>('beneficiary_member_id'),
      scope: effectiveScopeStr != null
          ? ExpenseScope.fromCode(effectiveScopeStr)
          : null,
      isRecurring:
          (row.readNullable<int>('ctx_is_recurring') ?? 0) == 1 ||
          row.read<bool>('is_recurring'),
      note:
          row.readNullable<String>('ctx_note') ??
          row.readNullable<String>('description'),
      spenderName: row.readNullable<String>('spender_name'),
      beneficiaryName: row.readNullable<String>('beneficiary_name'),
      sourceAccountName: row.readNullable<String>('source_account_name'),
      destinationAccountName: row.readNullable<String>(
        'destination_account_name',
      ),
      createdByName: row.readNullable<String>('created_by_name'),
    );
  }
}
