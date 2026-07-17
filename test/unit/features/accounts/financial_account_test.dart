import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

FinancialAccount _account({
  String id = 'acc-1',
  String householdId = 'hh-1',
  String name = 'Test Account',
  FinancialAccountType type = FinancialAccountType.personalCashWallet,
  AccountOwnerType ownerType = AccountOwnerType.user,
  FundPurpose fundPurpose = FundPurpose.available,
  String currencyCode = 'EGP',
  bool isSpendable = true,
  bool isProtected = false,
  bool includeInNetWorth = true,
  bool includeInZakat = false,
  bool isArchived = false,
  int displayOrder = 0,
  String createdBy = 'user-1',
}) => FinancialAccount(
  id: id,
  householdId: householdId,
  name: name,
  type: type,
  ownerType: ownerType,
  fundPurpose: fundPurpose,
  currencyCode: currencyCode,
  isSpendable: isSpendable,
  isProtected: isProtected,
  includeInNetWorth: includeInNetWorth,
  includeInZakat: includeInZakat,
  isArchived: isArchived,
  displayOrder: displayOrder,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: createdBy,
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('FinancialAccount – construction and immutability', () {
    test('creates with all required fields', () {
      final acc = _account();
      expect(acc.id, 'acc-1');
      expect(acc.type, FinancialAccountType.personalCashWallet);
      expect(acc.currencyCode, 'EGP');
      expect(acc.isArchived, isFalse);
    });

    test('type is excluded from copyWith (immutable after creation)', () {
      final acc = _account(type: FinancialAccountType.bankAccount);
      // copyWith does not accept type; the returned object preserves the original
      final modified = acc.copyWith(name: 'New Name');
      expect(modified.type, FinancialAccountType.bankAccount);
    });

    test('currencyCode is excluded from copyWith (immutable after creation)', () {
      final acc = _account(currencyCode: 'USD');
      final modified = acc.copyWith(name: 'New Name');
      expect(modified.currencyCode, 'USD');
    });

    test('copyWith preserves id and householdId', () {
      final acc = _account(id: 'acc-42', householdId: 'hh-99');
      final modified = acc.copyWith(name: 'Updated');
      expect(modified.id, 'acc-42');
      expect(modified.householdId, 'hh-99');
    });

    test('copyWith allows updating mutable fields', () {
      final acc = _account(isSpendable: true, isProtected: false);
      final updated = acc.copyWith(
        isSpendable: false,
        isProtected: true,
        name: 'Protected',
        isArchived: true,
        displayOrder: 5,
        notes: 'Test note',
      );
      expect(updated.isSpendable, isFalse);
      expect(updated.isProtected, isTrue);
      expect(updated.name, 'Protected');
      expect(updated.isArchived, isTrue);
      expect(updated.displayOrder, 5);
      expect(updated.notes, 'Test note');
    });
  });

  group('FinancialAccount – equality', () {
    test('equal when same id and householdId', () {
      final a = _account(id: 'a1', householdId: 'hh-1');
      final b = _account(id: 'a1', householdId: 'hh-1', name: 'Different Name');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when different id', () {
      final a = _account(id: 'a1');
      final b = _account(id: 'a2');
      expect(a, isNot(equals(b)));
    });
  });

  group('FinancialAccount – protected-fund predicates', () {
    test('childProtectedFund type always requiresWithdrawalAudit', () {
      final acc = _account(
        type: FinancialAccountType.childProtectedFund,
        isProtected: false, // even if false, type forces audit
      );
      expect(acc.requiresWithdrawalAudit, isTrue);
    });

    test('isProtected flag triggers requiresWithdrawalAudit even for other types', () {
      final acc = _account(type: FinancialAccountType.personalCashWallet, isProtected: true);
      expect(acc.requiresWithdrawalAudit, isTrue);
    });

    test('normal account does not require withdrawal audit', () {
      final acc = _account(type: FinancialAccountType.personalCashWallet, isProtected: false);
      expect(acc.requiresWithdrawalAudit, isFalse);
    });

    test('isChildProtectedFund is true only for childProtectedFund type', () {
      expect(_account(type: FinancialAccountType.childProtectedFund).isChildProtectedFund, isTrue);
      expect(_account(type: FinancialAccountType.bankAccount).isChildProtectedFund, isFalse);
    });
  });

  group('FinancialAccount – archived state', () {
    test('archived account preserves all fields', () {
      final acc = _account(isArchived: false);
      final archived = acc.copyWith(
        isArchived: true,
        archivedAt: DateTime.utc(2024, 6, 1),
        updatedAt: '2024-06-01T00:00:00Z',
      );
      expect(archived.isArchived, isTrue);
      expect(archived.archivedAt, isNotNull);
      expect(archived.name, acc.name);
      expect(archived.type, acc.type);
    });
  });

  group('FinancialAccountType enum', () {
    test('fromCode round-trips all values', () {
      for (final t in FinancialAccountType.values) {
        expect(FinancialAccountType.fromCode(t.code), t);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => FinancialAccountType.fromCode('unknownType'), throwsArgumentError);
    });

    test('only childProtectedFund requiresProtectedWithdrawalAudit', () {
      for (final t in FinancialAccountType.values) {
        if (t == FinancialAccountType.childProtectedFund) {
          expect(t.requiresProtectedWithdrawalAudit, isTrue, reason: t.code);
        } else {
          expect(t.requiresProtectedWithdrawalAudit, isFalse, reason: t.code);
        }
      }
    });
  });

  group('AccountOwnerType enum', () {
    test('fromCode round-trips all values', () {
      for (final t in AccountOwnerType.values) {
        expect(AccountOwnerType.fromCode(t.code), t);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => AccountOwnerType.fromCode('ghost'), throwsArgumentError);
    });
  });

  group('FundPurpose enum', () {
    test('fromCode round-trips all values', () {
      for (final t in FundPurpose.values) {
        expect(FundPurpose.fromCode(t.code), t);
      }
    });
  });

  group('CreateAccountParams', () {
    test('can be constructed with required fields', () {
      const params = CreateAccountParams(
        id: 'acc-1',
        householdId: 'hh-1',
        name: 'Wallet',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'user-1',
      );
      expect(params.id, 'acc-1');
      expect(params.type, FinancialAccountType.personalCashWallet);
    });
  });
}
