/// Tests for [CertificatePrincipalProtection].
///
/// Rule under test: certificate principal is protected money for as long as
/// the contractual term has not ended, and stops being protected once maturity
/// is reached. The boundary is derived from the clock on every read because
/// `financial_accounts.is_protected` is immutable after creation.
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/accounts/application/account_totals_service.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/domain/certificate_principal_protection.dart';
import 'package:flutter_test/flutter_test.dart';

bool _protectedOn(String today, {CertificateLifecycle lifecycle = CertificateLifecycle.active, int principal = 100000}) =>
    CertificatePrincipalProtection.isProtectedOn(
      lifecycle: lifecycle,
      startDate: '2026-01-01',
      maturityDate: '2027-01-01',
      todayLocal: today,
      principalBalanceMinorUnits: principal,
    );

FinancialAccount _certificateAccount(String id) => FinancialAccount(
  id: id,
  householdId: 'hh-1',
  name: 'Certificate: Bank 1',
  type: FinancialAccountType.certificate,
  ownerType: AccountOwnerType.household,
  fundPurpose: FundPurpose.certificate,
  currencyCode: 'EGP',
  // As created by CreateCertificateUseCase: neither spendable nor flagged
  // protected — protection is derived from the term, not stored.
  isSpendable: false,
  isProtected: false,
  includeInNetWorth: true,
  includeInZakat: false,
  isArchived: false,
  displayOrder: 9999,
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
  createdBy: 'system',
);

void main() {
  group('CertificatePrincipalProtection.isProtectedOn', () {
    test('protected before the term starts', () {
      expect(_protectedOn('2025-12-31'), isTrue);
    });

    test('protected on the first day of the term', () {
      expect(_protectedOn('2026-01-01'), isTrue);
    });

    test('protected in the middle of the term', () {
      expect(_protectedOn('2026-07-01'), isTrue);
    });

    test('protected on the last day before maturity', () {
      expect(_protectedOn('2026-12-31'), isTrue);
    });

    test('NOT protected on the maturity date itself', () {
      // Term has ended: the principal is claimable and must surface as
      // awaiting redemption rather than hide inside the protected total.
      expect(_protectedOn('2027-01-01'), isFalse);
    });

    test('NOT protected after maturity (overdue redemption)', () {
      expect(_protectedOn('2027-03-01'), isFalse);
    });

    test('NOT protected once redeemed, even inside the original term', () {
      expect(_protectedOn('2026-07-01', lifecycle: CertificateLifecycle.redeemed, principal: 0), isFalse);
    });

    test('NOT protected when archived with zero principal', () {
      expect(_protectedOn('2026-07-01', lifecycle: CertificateLifecycle.archived, principal: 0), isFalse);
    });
  });

  group('CertificatePrincipalProtection.isProtectedInTermState', () {
    test('maps every term state to the documented protection', () {
      const expected = <CertificateTermState, bool>{
        CertificateTermState.notStarted: true,
        CertificateTermState.activeTerm: true,
        CertificateTermState.matured: false,
        CertificateTermState.overdueRedemption: false,
        CertificateTermState.fullyRedeemed: false,
      };
      // Fails if a new term state is added without deciding its protection.
      expect(expected.keys.toSet(), CertificateTermState.values.toSet());
      for (final entry in expected.entries) {
        expect(CertificatePrincipalProtection.isProtectedInTermState(entry.key), entry.value, reason: 'term state ${entry.key.name}');
      }
    });
  });

  group('AccountTotalsService with derived certificate protection', () {
    test('in-term certificate principal counts as protected, not spendable', () {
      final totals = AccountTotalsService.compute(
        accounts: [_certificateAccount('cert-1')],
        balancesByAccountId: {'cert-1': 500000},
        derivedProtectedAccountIds: {'cert-1'},
      );

      expect(totals, hasLength(1));
      expect(totals.single.currency, Currency.egp);
      expect(totals.single.protectedMinorUnits, 500000);
      expect(totals.single.spendableMinorUnits, 0);
    });

    test('matured certificate contributes to neither total', () {
      // Not protected any more, and still not spendable — the account is
      // reachable only through the redemption workflow (INV-004A).
      final totals = AccountTotalsService.compute(
        accounts: [_certificateAccount('cert-1')],
        balancesByAccountId: {'cert-1': 500000},
        derivedProtectedAccountIds: const {},
      );

      expect(totals.single.protectedMinorUnits, 0);
      expect(totals.single.spendableMinorUnits, 0);
    });

    test('derived protection never inflates the spendable total', () {
      const cash = FinancialAccount(
        id: 'cash-1',
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
        isArchived: false,
        displayOrder: 0,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
        createdBy: 'user',
      );

      final totals = AccountTotalsService.compute(
        accounts: [cash, _certificateAccount('cert-1')],
        balancesByAccountId: {'cash-1': 20000, 'cert-1': 500000},
        derivedProtectedAccountIds: {'cert-1'},
      );

      expect(totals.single.spendableMinorUnits, 20000);
      expect(totals.single.protectedMinorUnits, 500000);
    });

    test('archived certificate is excluded from totals entirely (INV-015)', () {
      final archived = _certificateAccount('cert-1').copyWith(isArchived: true);
      final totals = AccountTotalsService.compute(accounts: [archived], balancesByAccountId: {'cert-1': 500000}, derivedProtectedAccountIds: {'cert-1'});

      expect(totals.single.protectedMinorUnits, 0);
      expect(totals.single.spendableMinorUnits, 0);
    });
  });
}
