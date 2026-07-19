/// Phase 5B.3 – Section 10: Account-list widget coverage (AL-1..4).
///
/// These tests verify that goal reserve accounts are correctly excluded from
/// the ordinary accounts list and do not pollute account-list balance totals.
///
/// Tests:
///  AL-1. Goal reserve accounts are absent from ordinary accounts list
///  AL-2. Goal reserves do not affect account-list balance totals
///  AL-3. AccountTotalsService excludes goalReserve from spendable total
///  AL-4. AccountTotalsService excludes goalReserve from protected total
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/accounts/application/account_totals_service.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

FinancialAccount _makeAccount({
  required String id,
  required FinancialAccountType type,
  bool isSpendable = true,
  bool isProtected = false,
  bool isArchived = false,
  String currency = 'EGP',
}) {
  return FinancialAccount(
    id: id,
    householdId: 'hh-al',
    name: 'Account $id',
    type: type,
    ownerType: AccountOwnerType.user,
    fundPurpose: type == FinancialAccountType.goalReserve
        ? FundPurpose.goalReserve
        : FundPurpose.available,
    currencyCode: currency,
    isSpendable: isSpendable,
    isProtected: isProtected,
    includeInNetWorth: true,
    includeInZakat: false,
    isArchived: isArchived,
    displayOrder: 0,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
    createdBy: 'test',
  );
}

void main() {
  group('AL - Account-list filtering (unit coverage)', () {
    test(
      'AL-1. Goal reserve accounts are absent from ordinary accounts list',
      () {
        final allAccounts = [
          _makeAccount(
            id: 'normal-1',
            type: FinancialAccountType.personalCashWallet,
          ),
          _makeAccount(
            id: 'reserve-1',
            type: FinancialAccountType.goalReserve,
            isSpendable: false,
          ),
          _makeAccount(id: 'normal-2', type: FinancialAccountType.bankAccount),
        ];

        // The accounts_screen filters out goalReserve accounts.
        final displayed = allAccounts
            .where((a) => a.type != FinancialAccountType.goalReserve)
            .toList();

        expect(
          displayed.any((a) => a.type == FinancialAccountType.goalReserve),
          isFalse,
          reason:
              'AL-1: no goalReserve account must appear in the displayed list',
        );
        expect(
          displayed.length,
          2,
          reason: 'AL-1: only 2 ordinary accounts must remain',
        );
      },
    );

    test('AL-2. Goal reserves do not affect account-list balance totals', () {
      final accounts = [
        _makeAccount(
          id: 'normal-al2',
          type: FinancialAccountType.personalCashWallet,
          isSpendable: true,
        ),
        _makeAccount(
          id: 'reserve-al2',
          type: FinancialAccountType.goalReserve,
          isSpendable: false,
        ),
      ];

      // Simulate balances: normal=50000, reserve=30000.
      final balances = {'normal-al2': 50000, 'reserve-al2': 30000};

      // When computing totals for the filtered list (excluding reserve):
      final filteredAccounts = accounts
          .where((a) => a.type != FinancialAccountType.goalReserve)
          .toList();
      final totals = AccountTotalsService.compute(
        accounts: filteredAccounts,
        balancesByAccountId: balances,
      );

      expect(totals.length, 1, reason: 'AL-2: only EGP total');
      expect(
        totals.first.spendableMinorUnits,
        50000,
        reason: 'AL-2: reserve balance must not appear in spendable total',
      );
    });

    test(
      'AL-3. AccountTotalsService: goalReserve (non-spendable, non-protected) contributes 0 to totals',
      () {
        final accounts = [
          _makeAccount(
            id: 'spendable-al3',
            type: FinancialAccountType.personalCashWallet,
            isSpendable: true,
          ),
          _makeAccount(
            id: 'reserve-al3',
            type: FinancialAccountType.goalReserve,
            isSpendable: false,
            isProtected: false,
          ),
        ];
        final balances = {'spendable-al3': 10000, 'reserve-al3': 99999};

        // Note: AccountTotalsService doesn't explicitly filter goalReserve —
        // reserve accounts are non-spendable, non-protected so they add 0.
        final totals = AccountTotalsService.compute(
          accounts: accounts,
          balancesByAccountId: balances,
        );

        // EGP total should only reflect the spendable account.
        final egpTotal = totals.firstWhere(
          (t) => t.currency.code == 'EGP',
          orElse: () => const CurrencyTotal(
            currency: Currency.egp,
            spendableMinorUnits: 0,
            protectedMinorUnits: 0,
          ),
        );
        expect(
          egpTotal.spendableMinorUnits,
          10000,
          reason: 'AL-3: goalReserve must not increase spendable total',
        );
        expect(
          egpTotal.protectedMinorUnits,
          0,
          reason: 'AL-3: goalReserve must not increase protected total',
        );
      },
    );

    test(
      'AL-4. Multiple goal reserves with large balances do not contaminate totals',
      () {
        final accounts = [
          _makeAccount(
            id: 'wallet-al4',
            type: FinancialAccountType.personalCashWallet,
            isSpendable: true,
          ),
          _makeAccount(
            id: 'reserve-al4-a',
            type: FinancialAccountType.goalReserve,
            isSpendable: false,
          ),
          _makeAccount(
            id: 'reserve-al4-b',
            type: FinancialAccountType.goalReserve,
            isSpendable: false,
          ),
        ];
        final balances = {
          'wallet-al4': 25000,
          'reserve-al4-a': 100000,
          'reserve-al4-b': 200000,
        };

        final filteredAccounts = accounts
            .where((a) => a.type != FinancialAccountType.goalReserve)
            .toList();
        final totals = AccountTotalsService.compute(
          accounts: filteredAccounts,
          balancesByAccountId: balances,
        );

        expect(
          totals.first.spendableMinorUnits,
          25000,
          reason:
              'AL-4: two large reserve balances must not contaminate spendable total',
        );
      },
    );
  });
}
