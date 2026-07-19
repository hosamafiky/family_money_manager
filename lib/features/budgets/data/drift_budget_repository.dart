import 'package:drift/drift.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/features/budgets/data/budget_repository.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';

/// Drift-backed implementation of [BudgetRepository].
///
/// All monetary totals stay per-currency. No cross-currency aggregation.
final class DriftBudgetRepository implements BudgetRepository {
  const DriftBudgetRepository(this._db);

  final AppDatabase _db;

  // ── createBudget ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<BudgetPlan>> createBudget(BudgetPlan plan) async {
    try {
      final existing = await _db
          .customSelect(
            'SELECT id, idempotency_payload FROM budgets '
            'WHERE household_id = ? AND idempotency_key = ?',
            variables: [Variable.withString(plan.householdId), Variable.withString(plan.idempotencyKey)],
          )
          .get();

      if (existing.isNotEmpty) {
        final row = existing.first;
        final storedPayload = row.read<String>('idempotency_payload');
        if (storedPayload == plan.idempotencyPayload) {
          final existingId = row.read<String>('id');
          final found = await _findById(existingId);
          if (found != null) return AppOk(found);
        }
        return const AppDuplicateConflict(messageKey: 'errorBudgetIdempotencyConflict');
      }

      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: plan.id,
              householdId: plan.householdId,
              name: plan.name,
              currencyCode: plan.currencyCode,
              limitMinorUnits: plan.limitMinorUnits,
              periodType: _periodTypeCode(plan.periodDefinition),
              fixedStartDate: Value(_fixedStart(plan.periodDefinition)),
              fixedEndDate: Value(_fixedEnd(plan.periodDefinition)),
              filterCategoryCode: Value(plan.filter.categoryCode),
              filterScopeCode: Value(plan.filter.scopeCode),
              filterSpenderMemberId: Value(plan.filter.spenderMemberId),
              filterBeneficiaryMemberId: Value(plan.filter.beneficiaryMemberId),
              filterPaymentAccountId: Value(plan.filter.paymentAccountId),
              isArchived: Value(plan.isArchived ? 1 : 0),
              idempotencyKey: plan.idempotencyKey,
              idempotencyPayload: plan.idempotencyPayload,
              createdAt: plan.createdAt,
              updatedAt: plan.updatedAt,
            ),
          );

      return AppOk(plan);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── updateBudget ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<BudgetPlan>> updateBudget(BudgetPlan plan) async {
    try {
      final existing = await _findById(plan.id);
      if (existing == null) return const AppNotFound();

      await (_db.update(_db.budgets)..where((t) => t.id.equals(plan.id))).write(
        BudgetsCompanion(
          name: Value(plan.name),
          limitMinorUnits: Value(plan.limitMinorUnits),
          filterCategoryCode: Value(plan.filter.categoryCode),
          filterScopeCode: Value(plan.filter.scopeCode),
          filterSpenderMemberId: Value(plan.filter.spenderMemberId),
          filterBeneficiaryMemberId: Value(plan.filter.beneficiaryMemberId),
          filterPaymentAccountId: Value(plan.filter.paymentAccountId),
          updatedAt: Value(plan.updatedAt),
        ),
      );

      return AppOk(plan);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── archiveBudget ─────────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> archiveBudget(String budgetId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final count = await (_db.update(
        _db.budgets,
      )..where((t) => t.id.equals(budgetId))).write(BudgetsCompanion(isArchived: const Value(1), updatedAt: Value(now)));
      if (count == 0) return const AppNotFound();
      return const AppOk(null);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── restoreBudget ─────────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> restoreBudget(String budgetId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final count = await (_db.update(
        _db.budgets,
      )..where((t) => t.id.equals(budgetId))).write(BudgetsCompanion(isArchived: const Value(0), updatedAt: Value(now)));
      if (count == 0) return const AppNotFound();
      return const AppOk(null);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── findBudgetById ────────────────────────────────────────────────────────

  @override
  Future<AppResult<BudgetPlan?>> findBudgetById(String budgetId) async {
    try {
      final plan = await _findById(budgetId);
      return AppOk(plan);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── listBudgets ───────────────────────────────────────────────────────────

  @override
  Future<AppResult<List<BudgetPlan>>> listBudgets({required String householdId, bool includeArchived = false}) async {
    try {
      final archivedClause = includeArchived ? '' : 'AND is_archived = 0';
      final rows = await _db
          .customSelect(
            'SELECT * FROM budgets '
            'WHERE household_id = ? $archivedClause '
            'ORDER BY created_at DESC',
            variables: [Variable.withString(householdId)],
          )
          .get();
      return AppOk(rows.map(_rowToPlan).toList());
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── getBudgetTransactions ─────────────────────────────────────────────────

  /// Budget transaction query using **restated semantics**.
  ///
  /// Differences from the report period-activity model:
  /// - Expenses where `is_reversed = 1` are excluded (they contribute zero
  ///   to budget consumption after being fully reversed).
  /// - Reversal operations (`type = 'reversal'`) are also excluded — they
  ///   never become negative consumption.
  ///
  /// All results are ordered by effective_date ASC, operation_id ASC.
  @override
  Future<AppResult<List<BudgetTransactionRow>>> getBudgetTransactions({
    required String householdId,
    required String currencyCode,
    required String periodStart,
    required String periodEnd,
    required BudgetFilter filter,
  }) async {
    try {
      final conditions = StringBuffer('''
        o.household_id = ?
        AND o.currency_code = ?
        AND o.type = 'expense'
        AND o.is_reversed = 0
        AND o.effective_date >= ?
        AND o.effective_date < ?
      ''');

      final vars = <Variable<Object>>[
        Variable.withString(householdId),
        Variable.withString(currencyCode),
        Variable.withString(periodStart),
        Variable.withString(periodEnd),
      ];

      if (filter.categoryCode != null) {
        conditions.write(' AND COALESCE(oc.category_code, o.category_code) = ?');
        vars.add(Variable.withString(filter.categoryCode!));
      }
      if (filter.scopeCode != null) {
        conditions.write(' AND COALESCE(oc.expense_scope, o.scope) = ?');
        vars.add(Variable.withString(filter.scopeCode!));
      }
      if (filter.spenderMemberId != null) {
        conditions.write(' AND oc.spender_member_id = ?');
        vars.add(Variable.withString(filter.spenderMemberId!));
      }
      if (filter.beneficiaryMemberId != null) {
        conditions.write(' AND oc.beneficiary_member_id = ?');
        vars.add(Variable.withString(filter.beneficiaryMemberId!));
      }
      if (filter.paymentAccountId != null) {
        conditions.write(' AND o.source_account_id = ?');
        vars.add(Variable.withString(filter.paymentAccountId!));
      }

      final sql =
          '''
        SELECT
          o.id AS operation_id,
          o.effective_date,
          o.total_amount_minor_units,
          o.currency_code,
          COALESCE(oc.category_code, o.category_code) AS category_code,
          oc.note,
          o.is_reversed
        FROM operations o
        LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
        WHERE $conditions
        ORDER BY o.effective_date ASC, o.id ASC
        LIMIT 500
      ''';

      final rows = await _db.customSelect(sql, variables: vars).get();

      final result = rows.map((r) {
        return BudgetTransactionRow(
          operationId: r.read<String>('operation_id'),
          effectiveDate: r.read<String>('effective_date'),
          amountMinorUnits: r.read<int>('total_amount_minor_units'),
          currencyCode: r.read<String>('currency_code'),
          categoryCode: r.readNullable<String>('category_code'),
          note: r.readNullable<String>('note'),
          isReversed: r.read<int>('is_reversed') == 1,
        );
      }).toList();

      return AppOk(result);
    } catch (e) {
      return const AppPersistenceFailure();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<BudgetPlan?> _findById(String id) async {
    final rows = await _db.customSelect('SELECT * FROM budgets WHERE id = ?', variables: [Variable.withString(id)]).get();
    if (rows.isEmpty) return null;
    return _rowToPlan(rows.first);
  }

  BudgetPlan _rowToPlan(QueryRow row) {
    final periodTypeCode = row.read<String>('period_type');
    final fixedStart = row.readNullable<String>('fixed_start_date');
    final fixedEnd = row.readNullable<String>('fixed_end_date');

    BudgetPeriodDefinition period;
    if (periodTypeCode == 'fixed' && fixedStart != null && fixedEnd != null) {
      period = FixedBudgetPeriod(startDateInclusive: fixedStart, endDateExclusive: fixedEnd);
    } else {
      period = const MonthlyBudgetPeriod();
    }

    return BudgetPlan(
      id: row.read<String>('id'),
      householdId: row.read<String>('household_id'),
      name: row.read<String>('name'),
      currencyCode: row.read<String>('currency_code'),
      limitMinorUnits: row.read<int>('limit_minor_units'),
      periodDefinition: period,
      filter: BudgetFilter(
        categoryCode: row.readNullable<String>('filter_category_code'),
        scopeCode: row.readNullable<String>('filter_scope_code'),
        spenderMemberId: row.readNullable<String>('filter_spender_member_id'),
        beneficiaryMemberId: row.readNullable<String>('filter_beneficiary_member_id'),
        paymentAccountId: row.readNullable<String>('filter_payment_account_id'),
      ),
      isArchived: row.read<int>('is_archived') == 1,
      createdAt: row.read<String>('created_at'),
      updatedAt: row.read<String>('updated_at'),
      idempotencyKey: row.read<String>('idempotency_key'),
      idempotencyPayload: row.read<String>('idempotency_payload'),
    );
  }

  String _periodTypeCode(BudgetPeriodDefinition def) => switch (def) {
    MonthlyBudgetPeriod() => 'monthly',
    FixedBudgetPeriod() => 'fixed',
  };

  String? _fixedStart(BudgetPeriodDefinition def) => def is FixedBudgetPeriod ? def.startDateInclusive : null;

  String? _fixedEnd(BudgetPeriodDefinition def) => def is FixedBudgetPeriod ? def.endDateExclusive : null;
}
