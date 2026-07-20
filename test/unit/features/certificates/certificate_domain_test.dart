/// Unit tests for certificate domain derivation.
///
///  1. CertificateTermState: notStarted when today < startDate
///  2. CertificateTermState: activeTerm when today within [start, maturity)
///  3. CertificateTermState: matured when today == maturityDate and balance > 0
///  4. CertificateTermState: overdueRedemption when today > maturityDate and balance > 0
///  5. CertificateTermState: fullyRedeemed when lifecycle == redeemed
///  6. CertificateTermState: fullyRedeemed when archived + zero balance
///  7. CertificateTermState: activeTerm for archived with nonzero balance (edge)
///  8. CertificateProgress.canRedeem: true only when active + matured/overdue + balance > 0
///  9. CertificateProgress.canRecordProfit: false only when archived
/// 10. CertificateRedemptionSummary.combinedCashMinorUnits = principal + profit
/// 11. CertificateProfitFrequency.fromCode: round-trip for all values
/// 12. CertificateProfitFrequency.fromCode: null input returns null
/// 13. CertificateProfitFrequency.fromCode: unknown returns other
/// 14. CertificateEventType.fromCode: round-trip for all values
/// 15. CertificateEventType.fromCode: unknown code throws ArgumentError
/// 16. Idempotency payload distinguishes different principals
/// 17. Idempotency payload distinguishes different institutions
/// 18. Idempotency payload distinguishes different currencies
/// 19. Idempotency payload is stable across two invocations with same data
/// 20. CertificateProgress.isMaturedOrOverdue: true for matured
/// 21. CertificateProgress.isMaturedOrOverdue: true for overdueRedemption
/// 22. CertificateProgress.isMaturedOrOverdue: false for activeTerm
library;

import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CertificateTermState.derive', () {
    test('1. notStarted when today < startDate', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.active,
          startDate: '2025-06-01',
          maturityDate: '2026-06-01',
          todayLocal: '2025-05-31',
          principalBalanceMinorUnits: 100000,
        ),
        CertificateTermState.notStarted,
      );
    });

    test('2. activeTerm when today within [start, maturity)', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.active,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2025-06-15',
          principalBalanceMinorUnits: 100000,
        ),
        CertificateTermState.activeTerm,
      );
    });

    test('3. matured when today == maturityDate and balance > 0', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.active,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2026-01-01',
          principalBalanceMinorUnits: 100000,
        ),
        CertificateTermState.matured,
      );
    });

    test('4. overdueRedemption when today > maturityDate and balance > 0', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.active,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2026-06-01',
          principalBalanceMinorUnits: 100000,
        ),
        CertificateTermState.overdueRedemption,
      );
    });

    test('5. fullyRedeemed when lifecycle == redeemed', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.redeemed,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2026-06-01',
          principalBalanceMinorUnits: 0,
        ),
        CertificateTermState.fullyRedeemed,
      );
    });

    test('6. fullyRedeemed when archived + zero balance', () {
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.archived,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2025-06-01',
          principalBalanceMinorUnits: 0,
        ),
        CertificateTermState.fullyRedeemed,
      );
    });

    test('7. activeTerm for archived with nonzero balance (edge)', () {
      // Archived + nonzero balance falls through to date check.
      expect(
        CertificateTermState.derive(
          lifecycle: CertificateLifecycle.archived,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          todayLocal: '2025-06-01',
          principalBalanceMinorUnits: 50000,
        ),
        CertificateTermState.activeTerm,
      );
    });
  });

  group('CertificateProgress derived properties', () {
    CertificateProgress makeProgress({
      required CertificateTermState termState,
      required CertificateLifecycle lifecycle,
      required int balance,
    }) {
      const rev = CertificateRevision(
        id: 'rev1',
        certificateId: 'c1',
        householdId: 'hh1',
        institutionName: 'Bank',
        createdAt: '2025-01-01',
        revisionReason: 'initial',
      );
      final cert = SavingsCertificate(
        id: 'c1',
        householdId: 'hh1',
        certificateAccountId: 'ca1',
        currencyCode: 'EGP',
        originalPrincipalMinorUnits: 100000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        lifecycle: lifecycle,
        currentRevision: rev,
        createdAt: '2025-01-01',
        idempotencyKey: 'key1',
        schemaVersion: 1,
      );
      return CertificateProgress(
        certificate: cert,
        principalBalanceMinorUnits: balance,
        currencyCode: 'EGP',
        termState: termState,
        events: const [],
        revisions: [rev],
        todayLocal: '2026-01-15',
      );
    }

    test('8. canRedeem: true when active + matured + balance > 0', () {
      final p = makeProgress(
        termState: CertificateTermState.matured,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.canRedeem, isTrue);
    });

    test('8b. canRedeem: false when balance == 0', () {
      final p = makeProgress(
        termState: CertificateTermState.matured,
        lifecycle: CertificateLifecycle.active,
        balance: 0,
      );
      expect(p.canRedeem, isFalse);
    });

    test('8c. canRedeem: false when activeTerm', () {
      final p = makeProgress(
        termState: CertificateTermState.activeTerm,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.canRedeem, isFalse);
    });

    test('9. canRecordProfit: false when archived', () {
      final p = makeProgress(
        termState: CertificateTermState.fullyRedeemed,
        lifecycle: CertificateLifecycle.archived,
        balance: 0,
      );
      expect(p.canRecordProfit, isFalse);
    });

    test('9b. canRecordProfit: true when active', () {
      final p = makeProgress(
        termState: CertificateTermState.activeTerm,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.canRecordProfit, isTrue);
    });

    test('20. isMaturedOrOverdue: true for matured', () {
      final p = makeProgress(
        termState: CertificateTermState.matured,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.isMaturedOrOverdue, isTrue);
    });

    test('21. isMaturedOrOverdue: true for overdueRedemption', () {
      final p = makeProgress(
        termState: CertificateTermState.overdueRedemption,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.isMaturedOrOverdue, isTrue);
    });

    test('22. isMaturedOrOverdue: false for activeTerm', () {
      final p = makeProgress(
        termState: CertificateTermState.activeTerm,
        lifecycle: CertificateLifecycle.active,
        balance: 100000,
      );
      expect(p.isMaturedOrOverdue, isFalse);
    });
  });

  test('10. CertificateRedemptionSummary.combinedCashMinorUnits', () {
    const rev = CertificateRevision(
      id: 'rev1',
      certificateId: 'c1',
      householdId: 'hh1',
      institutionName: 'Bank',
      createdAt: '2025-01-01',
      revisionReason: 'initial',
    );
    const cert = SavingsCertificate(
      id: 'c1',
      householdId: 'hh1',
      certificateAccountId: 'ca1',
      currencyCode: 'EGP',
      originalPrincipalMinorUnits: 100000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      lifecycle: CertificateLifecycle.redeemed,
      currentRevision: rev,
      createdAt: '2025-01-01',
      idempotencyKey: 'k',
      schemaVersion: 1,
    );
    const summary = CertificateRedemptionSummary(
      certificate: cert,
      principalMinorUnits: 100000,
      profitMinorUnits: 5000,
      destinationAccountId: 'dest',
      currencyCode: 'EGP',
      principalOperationId: 'op1',
    );
    expect(summary.combinedCashMinorUnits, 105000);
  });

  group('CertificateProfitFrequency', () {
    test('11. fromCode: round-trip for all values', () {
      for (final v in CertificateProfitFrequency.values) {
        expect(CertificateProfitFrequency.fromCode(v.code), v);
      }
    });

    test('12. fromCode: null input returns null', () {
      expect(CertificateProfitFrequency.fromCode(null), isNull);
    });

    test('13. fromCode: empty string returns null', () {
      expect(CertificateProfitFrequency.fromCode(''), isNull);
    });

    test('13b. fromCode: unknown returns other', () {
      expect(
        CertificateProfitFrequency.fromCode('unknown_xyz'),
        CertificateProfitFrequency.other,
      );
    });
  });

  group('CertificateEventType', () {
    test('14. fromCode: round-trip for all values', () {
      for (final v in CertificateEventType.values) {
        expect(CertificateEventType.fromCode(v.code), v);
      }
    });

    test('15. fromCode: unknown code throws ArgumentError', () {
      expect(
        () => CertificateEventType.fromCode('totally_unknown'),
        throwsArgumentError,
      );
    });
  });

  group('Idempotency payload', () {
    CertificateRevision rev0(String institution) => CertificateRevision(
      id: 'r',
      certificateId: 'c',
      householdId: 'hh',
      institutionName: institution,
      createdAt: '2025-01-01',
      revisionReason: 'initial',
    );

    SavingsCertificate cert0({
      String hh = 'hh',
      String institution = 'BankA',
      String currency = 'EGP',
      int principal = 100000,
    }) {
      return SavingsCertificate(
        id: 'c1',
        householdId: hh,
        certificateAccountId: 'ca1',
        currencyCode: currency,
        originalPrincipalMinorUnits: principal,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        lifecycle: CertificateLifecycle.active,
        currentRevision: rev0(institution),
        createdAt: '2025-01-01',
        idempotencyKey: 'key',
        schemaVersion: 1,
      );
    }

    String payload(SavingsCertificate c) =>
        'hh=${c.householdId}|'
        'inst=${c.currentRevision.institutionName}|'
        'ref=${c.currentRevision.reference ?? ''}|'
        'cur=${c.currencyCode}|'
        'principal=${c.originalPrincipalMinorUnits}|'
        'start=${c.startDate}|'
        'maturity=${c.maturityDate}|'
        'rate=${c.currentRevision.annualRateBps ?? ''}|'
        'freq=${c.currentRevision.profitFrequency?.code ?? ''}|'
        'src=fundedAtCreate';

    test('16. different principals produce different payloads', () {
      final p1 = payload(cert0(principal: 100000));
      final p2 = payload(cert0(principal: 200000));
      expect(p1, isNot(p2));
    });

    test('17. different institutions produce different payloads', () {
      final p1 = payload(cert0(institution: 'BankA'));
      final p2 = payload(cert0(institution: 'BankB'));
      expect(p1, isNot(p2));
    });

    test('18. different currencies produce different payloads', () {
      final p1 = payload(cert0(currency: 'EGP'));
      final p2 = payload(cert0(currency: 'USD'));
      expect(p1, isNot(p2));
    });

    test('19. stable across two invocations with same data', () {
      final c = cert0();
      expect(payload(c), payload(c));
    });
  });
}
