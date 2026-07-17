/// Account flow report DB tests (Phase 4B).
///
/// Tests:
///  1. Opening balance computed from pre-period entries
///  2. Income in period adds to flow
///  3. Expense in period reduces flow
///  4. Transfer in adds
///  5. Transfer out reduces
///  6. Adjustment handled
///  7. Reversal effect handled
///  8. Closing balance = opening + all effects (reconciliation invariant)
///  9. Multiple currencies separate
/// 10. Household isolation
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-acct';
const _hh2 = 'hh-acct-2';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftReportQueryRepository reportRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    reportRepo = DriftReportQueryRepository(db);

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'Acct HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  Future<String> createAccount(
    String id, {
    String householdId = _hh,
    String currency = 'EGP',
    String type = 'personalCashWallet',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
    return id;
  }

  Future<void> income(
    String householdId,
    String accId,
    String opId,
    int amount,
    String date,
  ) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: householdId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> expense(
    String householdId,
    String accId,
    String opId,
    int amount,
    String date,
  ) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: householdId,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  FinancialReportRequest req(
    String start,
    String end, {
    String householdId = _hh,
  }) {
    return FinancialReportRequest(
      householdId: householdId,
      period: DashboardPeriod.custom(startDate: start, endDate: end),
    );
  }

  group('report_account_flow_db', () {
    test('1. Opening balance computed from pre-period entries', () async {
      final acc = await createAccount('acc-af-1');
      // Pre-period income
      await income(_hh, acc, 'op-pre-1', 8000, '2024-12-15');

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);
      expect(
        flow.openingBalanceMinorUnits,
        8000,
        reason: 'Pre-period income becomes opening balance',
      );
    });

    test('2. Income in period adds to flow', () async {
      final acc = await createAccount('acc-af-2');
      await income(_hh, acc, 'op-af-2', 5000, '2025-01-10');

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);
      expect(flow.incomeMinorUnits, 5000);
    });

    test('3. Expense in period reduces flow', () async {
      final acc = await createAccount('acc-af-3');
      await income(_hh, acc, 'op-af-3-seed', 10000, '2025-01-01');
      await expense(_hh, acc, 'op-af-3', 3000, '2025-01-15');

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);
      expect(flow.expenseMinorUnits, 3000);
    });

    test('4. Transfer in adds', () async {
      final src = await createAccount('acc-af-4a');
      final dst = await createAccount('acc-af-4b');
      await income(_hh, src, 'op-af-4-seed', 10000, '2025-01-01');
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-tr-4',
          householdId: _hh,
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 4000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final dstFlow = result.firstWhere((r) => r.accountId == dst);
      expect(dstFlow.transfersInMinorUnits, 4000);
    });

    test('5. Transfer out reduces', () async {
      final src = await createAccount('acc-af-5a');
      final dst = await createAccount('acc-af-5b');
      await income(_hh, src, 'op-af-5-seed', 10000, '2025-01-01');
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-tr-5',
          householdId: _hh,
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 2500,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final srcFlow = result.firstWhere((r) => r.accountId == src);
      expect(srcFlow.transfersOutMinorUnits, 2500);
    });

    test('6. Adjustment handled', () async {
      final acc = await createAccount('acc-af-6');
      await income(_hh, acc, 'op-af-6-seed', 10000, '2025-01-01');
      await ledgerRepo.recordAdjustment(
        RecordAdjustmentParams(
          operationId: 'op-adj-6',
          householdId: _hh,
          accountId: acc,
          adjustmentAmountMinorUnits: 500,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-20',
          createdBy: 'test',
          reason: 'test adj',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);
      expect(
        flow.adjustmentsMinorUnits,
        500,
        reason: 'Credit adjustment = positive',
      );
    });

    test('7. Reversal effect handled', () async {
      final acc = await createAccount('acc-af-7');
      await income(_hh, acc, 'op-af-7-seed', 20000, '2025-01-01');
      await expense(_hh, acc, 'op-exp-af-7', 4000, '2025-01-10');
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev-af-7',
          originalOperationId: 'op-exp-af-7',
          householdId: _hh,
          effectiveDate: '2025-01-20',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);
      expect(
        flow.reversalEffectMinorUnits,
        4000,
        reason: 'Reversal restores funds (positive effect)',
      );
    });

    test('8. Closing balance reconciliation invariant holds', () async {
      final acc = await createAccount('acc-af-8');
      // Pre-period: opening = 5000
      await income(_hh, acc, 'op-pre-8', 5000, '2024-12-20');
      // Period: income = 3000, expense = 1000
      await income(_hh, acc, 'op-af-8-inc', 3000, '2025-01-10');
      await expense(_hh, acc, 'op-af-8-exp', 1000, '2025-01-15');

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final flow = result.firstWhere((r) => r.accountId == acc);

      expect(
        flow.reconciles,
        isTrue,
        reason:
            'opening + income - expense + transfersIn - transfersOut + adjustments + reversalEffect = closing',
      );
      expect(flow.openingBalanceMinorUnits, 5000);
      expect(flow.incomeMinorUnits, 3000);
      expect(flow.expenseMinorUnits, 1000);
      expect(flow.closingBalanceMinorUnits, 7000);
    });

    test('9. Multiple currencies separate', () async {
      final accEgp = await createAccount('acc-af-9a', currency: 'EGP');
      final accUsd = await createAccount('acc-af-9b', currency: 'USD');
      await income(_hh, accEgp, 'op-af-9-egp', 3000, '2025-01-10');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-af-9-usd',
          householdId: _hh,
          destinationAccountId: accUsd,
          amountMinorUnits: 1500,
          currencyCode: 'USD',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final egp = result.firstWhere((r) => r.accountId == accEgp);
      final usd = result.firstWhere((r) => r.accountId == accUsd);
      expect(egp.currencyCode, 'EGP');
      expect(usd.currencyCode, 'USD');
      expect(egp.incomeMinorUnits, 3000);
      expect(usd.incomeMinorUnits, 1500);
    });

    test('10. Household isolation', () async {
      final acc1 = await createAccount('acc-af-10a');
      final acc2 = await createAccount('acc-af-10b', householdId: _hh2);
      await income(_hh, acc1, 'op-af-10a', 4000, '2025-01-10');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-af-10b',
          householdId: _hh2,
          destinationAccountId: acc2,
          amountMinorUnits: 9000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.accountFlows(
        req('2025-01-01', '2025-02-01'),
      );
      expect(
        result.any((r) => r.accountId == acc2),
        isFalse,
        reason: 'HH2 account not in HH1 report',
      );
    });
  });
}
