/// Tests for [AccountTotalsService] (Phase 3A.1 §6).
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/accounts/application/account_totals_service.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:flutter_test/flutter_test.dart';

FinancialAccount _makeAccount({
  required String id,
  required String currencyCode,
  bool isSpendable = true,
  bool isProtected = false,
  bool isArchived = false,
}) => FinancialAccount(
  id: id,
  householdId: 'hh-1',
  name: 'Account $id',
  type: FinancialAccountType.personalCashWallet,
  ownerType: AccountOwnerType.user,
  fundPurpose: FundPurpose.available,
  currencyCode: currencyCode,
  isSpendable: isSpendable,
  isProtected: isProtected,
  includeInNetWorth: true,
  includeInZakat: false,
  isArchived: isArchived,
  displayOrder: 0,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: 'user-1',
);

void main() {
  group('AccountTotalsService.compute', () {
    test('single EGP account with positive balance → one EGP total', () {
      final accounts = [_makeAccount(id: 'a1', currencyCode: 'EGP')];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 5000},
      );

      expect(totals.length, 1);
      expect(totals.first.currency, Currency.egp);
      expect(totals.first.spendableMinorUnits, 5000);
    });

    test('EGP + USD accounts → two separate totals, no cross-currency sum', () {
      final accounts = [
        _makeAccount(id: 'egp1', currencyCode: 'EGP'),
        _makeAccount(id: 'usd1', currencyCode: 'USD'),
      ];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'egp1': 10000, 'usd1': 5000},
      );

      expect(totals.length, 2);
      final egpTotal = totals.firstWhere((t) => t.currency == Currency.egp);
      final usdTotal = totals.firstWhere((t) => t.currency == Currency.usd);
      expect(egpTotal.spendableMinorUnits, 10000);
      expect(usdTotal.spendableMinorUnits, 5000);
    });

    test('archived accounts are excluded from totals', () {
      final accounts = [
        _makeAccount(id: 'a1', currencyCode: 'EGP'),
        _makeAccount(id: 'a2', currencyCode: 'EGP', isArchived: true),
      ];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 3000, 'a2': 9000},
      );

      final egpTotal = totals.firstWhere((t) => t.currency == Currency.egp);
      expect(egpTotal.spendableMinorUnits, 3000);
    });

    test('non-spendable, non-protected accounts excluded from both totals', () {
      final accounts = [
        _makeAccount(
          id: 'a1',
          currencyCode: 'EGP',
          isSpendable: false,
          isProtected: false,
        ),
      ];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 50000},
      );

      expect(totals.length, 1);
      final egpTotal = totals.first;
      expect(egpTotal.spendableMinorUnits, 0);
      expect(egpTotal.protectedMinorUnits, 0);
    });

    test('protected account counted in protected total only', () {
      final accounts = [
        _makeAccount(
          id: 'a1',
          currencyCode: 'EGP',
          isSpendable: false,
          isProtected: true,
        ),
      ];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 7000},
      );

      final egpTotal = totals.first;
      expect(egpTotal.protectedMinorUnits, 7000);
      expect(egpTotal.spendableMinorUnits, 0);
    });

    test(
      'spendable (non-protected) account counted in spendable total only',
      () {
        final accounts = [_makeAccount(id: 'a1', currencyCode: 'EGP')];
        final totals = AccountTotalsService.compute(
          accounts: accounts,
          balancesByAccountId: {'a1': 2000},
        );

        final egpTotal = totals.first;
        expect(egpTotal.spendableMinorUnits, 2000);
        expect(egpTotal.protectedMinorUnits, 0);
      },
    );

    test('zero balance accounts included with zero amounts', () {
      final accounts = [_makeAccount(id: 'a1', currencyCode: 'EGP')];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 0},
      );

      expect(totals.length, 1);
      expect(totals.first.spendableMinorUnits, 0);
    });

    test('multiple EGP accounts summed correctly', () {
      final accounts = [
        _makeAccount(id: 'a1', currencyCode: 'EGP'),
        _makeAccount(id: 'a2', currencyCode: 'EGP'),
        _makeAccount(id: 'a3', currencyCode: 'EGP'),
      ];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'a1': 1000, 'a2': 2000, 'a3': 3000},
      );

      expect(totals.length, 1);
      expect(totals.first.spendableMinorUnits, 6000);
    });

    test('JPY (scale 0) account works correctly', () {
      final accounts = [_makeAccount(id: 'j1', currencyCode: 'JPY')];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'j1': 100000},
      );

      expect(totals.length, 1);
      expect(totals.first.currency, Currency.jpy);
      expect(totals.first.spendableMinorUnits, 100000);
    });

    test('KWD (scale 3) account works correctly', () {
      final accounts = [_makeAccount(id: 'k1', currencyCode: 'KWD')];
      final totals = AccountTotalsService.compute(
        accounts: accounts,
        balancesByAccountId: {'k1': 5000},
      );

      expect(totals.length, 1);
      expect(totals.first.currency, Currency.kwd);
      expect(totals.first.spendableMinorUnits, 5000);
    });
  });
}
