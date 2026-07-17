/// Spouse wallet report DB tests (Phase 4B).
///
/// Standard scenario: fund 2000 → spend 1300 → return 200 → closing 500.
///
/// Tests:
///  1. Standard scenario: funded=2000, spent=1300, returned=200, closing=500
///  2. Opening balance computed from pre-period entries
///  3. Period filter (only period activity in period flows)
///  4. Current balance = all-time balance
///  5. Multiple spouse wallets reported separately
///  6. Reversal of expense changes spent amount
///  7. Transfer-in not counted as income
///  8. Return (transferOut) not counted as negative expense
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

const _hh = 'hh-sw';
const _hh2 = 'hh-sw-2';

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
        "VALUES ('$h', 'SW HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  Future<String> createHomeSavings(String id, {String householdId = _hh}) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
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

  Future<String> createSpouseWallet(
    String id, {
    String householdId = _hh,
    String currency = 'EGP',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Spouse Wallet $id',
        type: FinancialAccountType.fromCode('spouseCashWallet'),
        ownerType: AccountOwnerType.spouse,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
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

  Future<void> seedHS(String hsId, String opId, int amount) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: _hh,
        destinationAccountId: hsId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<void> fund(
    String hsId,
    String walletId,
    String opId,
    int amount,
    String date, {
    String householdId = _hh,
  }) async {
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: opId,
        householdId: householdId,
        sourceAccountId: hsId,
        destinationAccountId: walletId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> spend(
    String walletId,
    String opId,
    int amount,
    String date, {
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: householdId,
        sourceAccountId: walletId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> returnFunds(
    String walletId,
    String hsId,
    String opId,
    int amount,
    String date,
  ) async {
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: opId,
        householdId: _hh,
        sourceAccountId: walletId,
        destinationAccountId: hsId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  FinancialReportRequest req(String start, String end, {String householdId = _hh}) {
    return FinancialReportRequest(
      householdId: householdId,
      period: DashboardPeriod.custom(startDate: start, endDate: end),
    );
  }

  group('report_spouse_wallet_db', () {
    test('1. Standard scenario: funded=2000, spent=1300, returned=200, closing=500', () async {
      final hs = await createHomeSavings('hs-sw-1');
      final wallet = await createSpouseWallet('wallet-sw-1');
      await seedHS(hs, 'op-sw-1-seed', 20000);

      await fund(hs, wallet, 'op-sw-1-fund', 2000, '2025-01-05');
      await spend(wallet, 'op-sw-1-spend', 1300, '2025-01-10');
      await returnFunds(wallet, hs, 'op-sw-1-return', 200, '2025-01-20');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);

      expect(walletReport.periodFundedMinorUnits, 2000);
      expect(walletReport.periodSpentMinorUnits, 1300);
      expect(walletReport.periodReturnedMinorUnits, 200);
      expect(
        walletReport.periodClosingBalanceMinorUnits,
        500,
        reason: 'opening(0) + funded(2000) - spent(1300) - returned(200) = 500',
      );
    });

    test('2. Opening balance computed from pre-period entries', () async {
      final hs = await createHomeSavings('hs-sw-2');
      final wallet = await createSpouseWallet('wallet-sw-2');
      await seedHS(hs, 'op-sw-2-seed', 20000);

      // Pre-period: fund 3000 → spend 1000 → opening = 2000
      await fund(hs, wallet, 'op-sw-2-pre-fund', 3000, '2024-12-15');
      await spend(wallet, 'op-sw-2-pre-spend', 1000, '2024-12-20');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      expect(
        walletReport.openingBalanceMinorUnits,
        2000,
        reason: 'Pre-period: 3000 funded - 1000 spent = 2000 opening',
      );
    });

    test('3. Period filter: only period activity in period flows', () async {
      final hs = await createHomeSavings('hs-sw-3');
      final wallet = await createSpouseWallet('wallet-sw-3');
      await seedHS(hs, 'op-sw-3-seed', 20000);

      // Pre-period funding
      await fund(hs, wallet, 'op-sw-3-pre', 1000, '2024-12-20');
      // Period funding
      await fund(hs, wallet, 'op-sw-3-in', 2000, '2025-01-10');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      expect(
        walletReport.periodFundedMinorUnits,
        2000,
        reason: 'Only period funding counted in periodFunded',
      );
      expect(walletReport.openingBalanceMinorUnits, 1000, reason: 'Pre-period 1000 = opening');
    });

    test('4. Current balance = all-time ledger balance', () async {
      final hs = await createHomeSavings('hs-sw-4');
      final wallet = await createSpouseWallet('wallet-sw-4');
      await seedHS(hs, 'op-sw-4-seed', 20000);

      await fund(hs, wallet, 'op-sw-4-fund', 5000, '2025-01-05');
      await spend(wallet, 'op-sw-4-spend', 3000, '2025-01-10');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      expect(
        walletReport.currentBalanceMinorUnits,
        2000,
        reason: 'All-time: 5000 funded - 3000 spent = 2000',
      );
    });

    test('5. Multiple spouse wallets reported separately', () async {
      final hs = await createHomeSavings('hs-sw-5');
      final wallet1 = await createSpouseWallet('wallet-sw-5a');
      final wallet2 = await createSpouseWallet('wallet-sw-5b');
      await seedHS(hs, 'op-sw-5-seed', 50000);

      await fund(hs, wallet1, 'op-sw-5a-fund', 3000, '2025-01-05');
      await fund(hs, wallet2, 'op-sw-5b-fund', 7000, '2025-01-05');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      expect(result.length, 2);
      final r1 = result.firstWhere((r) => r.accountId == wallet1);
      final r2 = result.firstWhere((r) => r.accountId == wallet2);
      expect(r1.periodFundedMinorUnits, 3000);
      expect(r2.periodFundedMinorUnits, 7000);
    });

    test('6. Reversal of expense changes spent amount', () async {
      final hs = await createHomeSavings('hs-sw-6');
      final wallet = await createSpouseWallet('wallet-sw-6');
      await seedHS(hs, 'op-sw-6-seed', 20000);

      await fund(hs, wallet, 'op-sw-6-fund', 5000, '2025-01-05');
      await spend(wallet, 'op-sw-6-spend', 2000, '2025-01-10');
      // Reverse the expense
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-sw-6-rev',
          originalOperationId: 'op-sw-6-spend',
          householdId: _hh,
          effectiveDate: '2025-01-15',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      // Reversal effect should appear as positive
      expect(
        walletReport.periodReversalEffectMinorUnits,
        greaterThan(0),
        reason: 'Reversal of expense restores funds',
      );
    });

    test('7. Transfer-in (funding) not counted as income', () async {
      final hs = await createHomeSavings('hs-sw-7');
      final wallet = await createSpouseWallet('wallet-sw-7');
      await seedHS(hs, 'op-sw-7-seed', 20000);
      await fund(hs, wallet, 'op-sw-7-fund', 4000, '2025-01-05');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      // funded = 4000 (transfer in), not income
      expect(walletReport.periodFundedMinorUnits, 4000);
      // If we query income/expense report, this should not appear as income
      final flows = await reportRepo.incomeExpenseFlow(
        FinancialReportRequest(
          householdId: _hh,
          period: DashboardPeriod.custom(startDate: '2025-01-01', endDate: '2025-02-01'),
        ),
      );
      expect(
        flows.isEmpty || flows.first.grossIncomeMinorUnits == 20000,
        isTrue,
        reason: 'Transfer not counted as income in flow report',
      );
    });

    test('8. Return not counted as negative expense', () async {
      final hs = await createHomeSavings('hs-sw-8');
      final wallet = await createSpouseWallet('wallet-sw-8');
      await seedHS(hs, 'op-sw-8-seed', 20000);
      await fund(hs, wallet, 'op-sw-8-fund', 3000, '2025-01-05');
      await returnFunds(wallet, hs, 'op-sw-8-ret', 1000, '2025-01-15');

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final walletReport = result.firstWhere((r) => r.accountId == wallet);
      expect(walletReport.periodSpentMinorUnits, 0, reason: 'Return is not expense');
      expect(walletReport.periodReturnedMinorUnits, 1000, reason: 'Return tracked separately');
    });

    test('9. Multiple currencies separate', () async {
      final hsEgp = await createHomeSavings('hs-sw-9a');
      final walletEgp = await createSpouseWallet('wallet-sw-9a');
      final walletUsd = await createSpouseWallet('wallet-sw-9b', currency: 'USD');
      await seedHS(hsEgp, 'op-sw-9-seed', 20000);

      await fund(hsEgp, walletEgp, 'op-sw-9-fund-egp', 3000, '2025-01-05');
      // USD wallet needs its own funding (but we can't fund from EGP account)
      // Seed USD wallet with opening balance
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'op-sw-9-usd-ob',
          householdId: _hh,
          accountId: walletUsd,
          amountMinorUnits: 500,
          currencyCode: 'USD',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      final egp = result.where((r) => r.currencyCode == 'EGP').toList();
      final usd = result.where((r) => r.currencyCode == 'USD').toList();
      expect(egp.isNotEmpty, isTrue);
      expect(usd.isNotEmpty, isTrue);
    });

    test('10. Household isolation', () async {
      final hs1 = await createHomeSavings('hs-sw-10a');
      final wallet1 = await createSpouseWallet('wallet-sw-10a');
      await seedHS(hs1, 'op-sw-10-seed', 20000);
      await fund(hs1, wallet1, 'op-sw-10-fund', 4000, '2025-01-05');

      // HH2 wallet
      final hs2 = await createHomeSavings('hs-sw-10b');
      final wallet2 = await createSpouseWallet('wallet-sw-10b', householdId: _hh2);
      await db.customStatement(
        "UPDATE financial_accounts SET household_id = '$_hh2' "
        "WHERE id = 'hs-sw-10b'",
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-sw-10b-seed',
          householdId: _hh2,
          destinationAccountId: hs2,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.spouseWalletReports(req('2025-01-01', '2025-02-01'));
      expect(
        result.any((r) => r.accountId == wallet2),
        isFalse,
        reason: 'HH2 wallet not in HH1 report',
      );
    });
  });
}
