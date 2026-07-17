/// Home savings flow report DB tests (Phase 4B).
///
/// Tests:
/// 1. Spouse wallet funding counted as transfer out
/// 2. Spouse wallet return counted as transfer in
/// 3. Direct expense counted
/// 4. Direct income counted
/// 5. Adjustment counted
/// 6. Closing balance reconciles
/// 7. Period filter works (pre-period = opening, period = flows)
/// 8. Multiple home savings accounts reported separately
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

const _hh = 'hh-hs';

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

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HS HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createHomeSavings(String id) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: 'Home Savings $id',
        type: FinancialAccountType.fromCode('homeSavingsCash'),
        ownerType: AccountOwnerType.household,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
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

  Future<String> createSpouseWallet(String id) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: 'Spouse Wallet $id',
        type: FinancialAccountType.fromCode('spouseCashWallet'),
        ownerType: AccountOwnerType.spouse,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 1,
        createdBy: 'test',
      ),
    );
    return id;
  }

  FinancialReportRequest req(String start, String end) {
    return FinancialReportRequest(
      householdId: _hh,
      period: DashboardPeriod.custom(startDate: start, endDate: end),
    );
  }

  group('report_home_savings_db', () {
    test('1. Spouse wallet funding counted as transfer out', () async {
      final hs = await createHomeSavings('hs-1');
      final wallet = await createSpouseWallet('wallet-1');
      // Seed home savings
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-1-seed',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 20000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      // Fund spouse wallet
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-hs-1-fund',
          householdId: _hh,
          sourceAccountId: hs,
          destinationAccountId: wallet,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(
        hsFlow.spouseWalletFundingMinorUnits,
        5000,
        reason: 'Transfer to spouseCashWallet = wallet funding',
      );
      expect(
        hsFlow.transfersOutMinorUnits,
        5000,
        reason: 'Also counted in total transfers out',
      );
    });

    test('2. Spouse wallet return counted as transfer in', () async {
      final hs = await createHomeSavings('hs-2');
      final wallet = await createSpouseWallet('wallet-2');
      // Seed both accounts
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-2-seed',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 20000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      // Fund wallet first (pre-period)
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-hs-2-fund',
          householdId: _hh,
          sourceAccountId: hs,
          destinationAccountId: wallet,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-12-20',
          createdBy: 'test',
        ),
      );
      // Return during period
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-hs-2-return',
          householdId: _hh,
          sourceAccountId: wallet,
          destinationAccountId: hs,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-15',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(
        hsFlow.spouseWalletReturnMinorUnits,
        2000,
        reason: 'Return from spouseCashWallet = wallet return',
      );
      expect(hsFlow.transfersInMinorUnits, 2000);
    });

    test('3. Direct expense counted', () async {
      final hs = await createHomeSavings('hs-3');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-3-seed',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 20000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-hs-3-exp',
          householdId: _hh,
          sourceAccountId: hs,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-15',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(hsFlow.directExpenseMinorUnits, 3000);
    });

    test('4. Direct income counted', () async {
      final hs = await createHomeSavings('hs-4');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-4-inc',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 12000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-05',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(hsFlow.directIncomeMinorUnits, 12000);
    });

    test('5. Adjustment counted', () async {
      final hs = await createHomeSavings('hs-5');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-5-seed',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordAdjustment(
        RecordAdjustmentParams(
          operationId: 'op-hs-5-adj',
          householdId: _hh,
          accountId: hs,
          adjustmentAmountMinorUnits: 300,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-20',
          createdBy: 'test',
          reason: 'test adj',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(hsFlow.adjustmentsMinorUnits, 300);
    });

    test('6. Closing balance reconciles with current', () async {
      final hs = await createHomeSavings('hs-6');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-6-inc',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-05',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-hs-6-exp',
          householdId: _hh,
          sourceAccountId: hs,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-20',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      // closing should be 10000 - 2000 = 8000
      expect(hsFlow.closingBalanceMinorUnits, 8000);
      expect(
        hsFlow.currentBalanceMinorUnits,
        8000,
        reason: 'No further ops, so current = closing',
      );
    });

    test('7. Period filter: pre-period income = opening', () async {
      final hs = await createHomeSavings('hs-7');
      // Pre-period income
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-7-pre',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 6000,
          currencyCode: 'EGP',
          effectiveDate: '2024-12-01',
          createdBy: 'test',
        ),
      );
      // Period income
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-7-in',
          householdId: _hh,
          destinationAccountId: hs,
          amountMinorUnits: 4000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      final hsFlow = result.firstWhere((r) => r.accountId == hs);
      expect(
        hsFlow.openingBalanceMinorUnits,
        6000,
        reason: 'Pre-period income = opening',
      );
      expect(
        hsFlow.directIncomeMinorUnits,
        4000,
        reason: 'Period income = direct income',
      );
    });

    test('8. Multiple home savings accounts reported separately', () async {
      final hs1 = await createHomeSavings('hs-8a');
      final hs2 = await createHomeSavings('hs-8b');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-8a-inc',
          householdId: _hh,
          destinationAccountId: hs1,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-05',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hs-8b-inc',
          householdId: _hh,
          destinationAccountId: hs2,
          amountMinorUnits: 7000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-05',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.homeSavingsFlows(
        req('2025-01-01', '2025-02-01'),
      );
      expect(result.length, 2);
      final f1 = result.firstWhere((r) => r.accountId == hs1);
      final f2 = result.firstWhere((r) => r.accountId == hs2);
      expect(f1.directIncomeMinorUnits, 5000);
      expect(f2.directIncomeMinorUnits, 7000);
    });
  });
}
