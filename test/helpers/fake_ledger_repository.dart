import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';

/// Minimal fake [LedgerRepository] for unit tests.
///
/// All write methods succeed with [IdempotentOperationResult.created].
/// All read methods return empty results.
final class FakeLedgerRepository implements LedgerRepository {
  final List<RecordOpeningBalanceParams> recordedOpeningBalances = [];

  @override
  Future<IdempotentOperationResult> recordIncome(RecordIncomeParams params) async =>
      IdempotentOperationResult.created;

  @override
  Future<IdempotentOperationResult> recordExpense(
    RecordExpenseParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async => IdempotentOperationResult.created;

  @override
  Future<IdempotentOperationResult> executeTransfer(
    ExecuteTransferParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async => IdempotentOperationResult.created;

  @override
  Future<IdempotentOperationResult> recordOpeningBalance(RecordOpeningBalanceParams params) async {
    recordedOpeningBalances.add(params);
    return IdempotentOperationResult.created;
  }

  @override
  Future<IdempotentOperationResult> recordAdjustment(
    RecordAdjustmentParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async => IdempotentOperationResult.created;

  @override
  Future<IdempotentOperationResult> reverseOperation(
    ReverseOperationParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async => IdempotentOperationResult.created;

  @override
  Future<List<LedgerEntry>> entriesForAccount({
    required String accountId,
    required String householdId,
  }) async => [];

  @override
  Future<Operation?> findOperation({
    required String operationId,
    required String householdId,
  }) async => null;

  @override
  Future<List<Operation>> operationsInRange({
    required String householdId,
    required String fromDate,
    required String toDate,
  }) async => [];
}
