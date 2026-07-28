/// DB tests for the third state of money.
///
/// `availableToSpend`, `excludedFromAvailable` and `heldByReason` partition
/// every non-archived account exactly once. The partition is the safety
/// property: money that fell out of all three would simply not appear on the
/// dashboard, which is the defect these queries exist to fix — certificate
/// principal and goal reserves were in neither the spendable nor the protected
/// bucket and had no figure anywhere.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-held';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftDashboardQueryRepository dashRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    dashRepo = DriftDashboardQueryRepository(db);
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'Held HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> account({
    required String id,
    required String type,
    bool isSpendable = true,
    bool isProtected = false,
    bool isArchived = false,
    String currency = 'EGP',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
        isSpendable: isSpendable,
        isProtected: isProtected,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
    if (isArchived) {
      await accountRepo.archiveAccount(
        id: id,
        householdId: _hh,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    return id;
  }

  Future<void> credit(String accountId, int amount, {String cur = 'EGP'}) =>
      ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-$accountId-$amount-$cur',
          householdId: _hh,
          destinationAccountId: accountId,
          amountMinorUnits: amount,
          currencyCode: cur,
          effectiveDate: '2026-07-01',
          createdBy: 'test',
        ),
      );

  int totalOf(List<CurrencyAmountSummary> rows, String currency) => rows
      .where((r) => r.currencyCode == currency)
      .fold(0, (sum, r) => sum + r.totalMinorUnits);

  int heldOf(List<HeldAmountSummary> rows, HeldReason reason) => rows
      .where((r) => r.reason == reason)
      .fold(0, (sum, r) => sum + r.totalMinorUnits);

  group('heldByReason', () {
    test('reports goal reserves, which no other query counts', () async {
      // The defect: a goalReserve account is not spendable and not protected,
      // so it appeared in neither existing bucket.
      await account(id: 'goal-1', type: 'goalReserve', isSpendable: false);
      await credit('goal-1', 1360000);

      final spendable = await dashRepo.spendableBalances(householdId: _hh);
      final protected = await dashRepo.protectedBalances(
        householdId: _hh,
        todayLocal: '2026-07-28',
      );
      final held = await dashRepo.heldByReason(householdId: _hh);

      expect(totalOf(spendable, 'EGP'), 0);
      expect(totalOf(protected, 'EGP'), 0);
      expect(heldOf(held, HeldReason.goalReserve), 1360000);
    });

    test('reports certificate principal under its own reason', () async {
      await account(id: 'cert-1', type: 'certificate', isSpendable: false);
      await credit('cert-1', 4790000);

      final held = await dashRepo.heldByReason(householdId: _hh);
      expect(heldOf(held, HeldReason.certificatePrincipal), 4790000);
    });

    test('reports child protected funds under their own reason', () async {
      await account(
        id: 'child-1',
        type: 'childProtectedFund',
        isSpendable: false,
        isProtected: true,
      );
      await credit('child-1', 695000);

      final held = await dashRepo.heldByReason(householdId: _hh);
      expect(heldOf(held, HeldReason.childProtected), 695000);
    });

    test('an unrecognised non-spendable type still gets a figure', () async {
      // `other` exists so money is never silently dropped for want of a label.
      await account(id: 'gold-1', type: 'goldHolding', isSpendable: false);
      await credit('gold-1', 500000);

      final held = await dashRepo.heldByReason(householdId: _hh);
      expect(heldOf(held, HeldReason.other), 500000);
    });

    test('excludes archived accounts', () async {
      await account(
        id: 'goal-archived',
        type: 'goalReserve',
        isSpendable: false,
      );
      await credit('goal-archived', 100000);
      await accountRepo.archiveAccount(
        id: 'goal-archived',
        householdId: _hh,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final held = await dashRepo.heldByReason(householdId: _hh);
      expect(heldOf(held, HeldReason.goalReserve), 0);
    });

    test('never combines currencies', () async {
      await account(id: 'goal-egp', type: 'goalReserve', isSpendable: false);
      await account(
        id: 'goal-usd',
        type: 'goalReserve',
        isSpendable: false,
        currency: 'USD',
      );
      await credit('goal-egp', 100000);
      await credit('goal-usd', 32000, cur: 'USD');

      final held = await dashRepo.heldByReason(householdId: _hh);
      final goal = held.where((h) => h.reason == HeldReason.goalReserve);
      expect(goal.map((h) => h.currencyCode).toSet(), {'EGP', 'USD'});
      expect(
        goal.firstWhere((h) => h.currencyCode == 'EGP').totalMinorUnits,
        100000,
      );
      expect(
        goal.firstWhere((h) => h.currencyCode == 'USD').totalMinorUnits,
        32000,
      );
    });
  });

  group('availableToSpend and excludedFromAvailable', () {
    test('a spouse wallet is spendable but not available', () async {
      await account(id: 'bank-1', type: 'bankAccount');
      await account(id: 'spouse-1', type: 'spouseCashWallet');
      await credit('bank-1', 2430000);
      await credit('spouse-1', 438250);

      final spendable = await dashRepo.spendableBalances(householdId: _hh);
      final available = await dashRepo.availableToSpend(householdId: _hh);
      final excluded = await dashRepo.excludedFromAvailable(householdId: _hh);

      // The pre-existing bucket still counts both — untouched by this change.
      expect(totalOf(spendable, 'EGP'), 2430000 + 438250);
      // The headline figure does not.
      expect(totalOf(available, 'EGP'), 2430000);
      expect(excluded.single.reason, ExclusionReason.spouseWallet);
      expect(excluded.single.totalMinorUnits, 438250);
    });

    test('with no spouse wallet, available equals spendable', () async {
      await account(id: 'bank-1', type: 'bankAccount');
      await credit('bank-1', 2430000);

      final spendable = await dashRepo.spendableBalances(householdId: _hh);
      final available = await dashRepo.availableToSpend(householdId: _hh);
      expect(totalOf(available, 'EGP'), totalOf(spendable, 'EGP'));
      expect(await dashRepo.excludedFromAvailable(householdId: _hh), isEmpty);
    });
  });

  group('the partition', () {
    test('every non-archived account lands in exactly one bucket', () async {
      // The safety property. If a future account type slipped through all
      // three predicates, its balance would vanish from the dashboard.
      await account(id: 'bank-1', type: 'bankAccount');
      await account(id: 'cash-1', type: 'personalCashWallet');
      await account(id: 'spouse-1', type: 'spouseCashWallet');
      await account(id: 'goal-1', type: 'goalReserve', isSpendable: false);
      await account(id: 'cert-1', type: 'certificate', isSpendable: false);
      await account(
        id: 'child-1',
        type: 'childProtectedFund',
        isSpendable: false,
        isProtected: true,
      );
      await account(id: 'gold-1', type: 'goldHolding', isSpendable: false);

      const amounts = {
        'bank-1': 2430000,
        'cash-1': 184500,
        'spouse-1': 438250,
        'goal-1': 1360000,
        'cert-1': 4790000,
        'child-1': 695000,
        'gold-1': 500000,
      };
      for (final entry in amounts.entries) {
        await credit(entry.key, entry.value);
      }

      final available = await dashRepo.availableToSpend(householdId: _hh);
      final excluded = await dashRepo.excludedFromAvailable(householdId: _hh);
      final held = await dashRepo.heldByReason(householdId: _hh);

      final grandTotal =
          totalOf(available, 'EGP') +
          excluded.fold<int>(0, (s, e) => s + e.totalMinorUnits) +
          held.fold<int>(0, (s, h) => s + h.totalMinorUnits);

      expect(grandTotal, amounts.values.reduce((a, b) => a + b));
    });

    test('held is exactly the complement of spendable', () async {
      await account(id: 'bank-1', type: 'bankAccount');
      await account(id: 'goal-1', type: 'goalReserve', isSpendable: false);
      await credit('bank-1', 2430000);
      await credit('goal-1', 1360000);

      final spendable = await dashRepo.spendableBalances(householdId: _hh);
      final held = await dashRepo.heldByReason(householdId: _hh);

      expect(
        totalOf(spendable, 'EGP') +
            held.fold<int>(0, (s, h) => s + h.totalMinorUnits),
        2430000 + 1360000,
      );
    });

    test('an empty household reports nothing rather than zeroes', () async {
      expect(await dashRepo.availableToSpend(householdId: _hh), isEmpty);
      expect(await dashRepo.excludedFromAvailable(householdId: _hh), isEmpty);
      expect(await dashRepo.heldByReason(householdId: _hh), isEmpty);
    });
  });
}
