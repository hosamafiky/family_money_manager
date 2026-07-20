/// Phase 6A.4 — Deterministic reversal fingerprint builders.
library;

import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FP-PUR-1. Purchase reversal fingerprint is deterministic', () {
    String build() => buildPurchaseReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalOperationId: 'op-purchase',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 40000,
      currencyCode: 'EGP',
      sourceAccountId: 'cash',
      destinationAccountId: 'cert-acct',
      reason: '  cancelled  ',
      createdBy: 'user',
    );
    expect(build(), build());
    expect(
      build(),
      'revType=purchaseReverse|hh=hh1|cert=cert1|origOp=op-purchase|'
      'date=2025-06-01|amt=40000|cur=EGP|src=cash|dst=cert-acct|'
      'reason=cancelled|actor=user',
    );
  });

  test('FP-PUR-2. Purchase reversal reason/actor change fingerprint', () {
    final a = buildPurchaseReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalOperationId: 'op-purchase',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 40000,
      currencyCode: 'EGP',
      sourceAccountId: 'cash',
      destinationAccountId: 'cert-acct',
      reason: 'a',
      createdBy: 'user',
    );
    final b = buildPurchaseReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalOperationId: 'op-purchase',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 40000,
      currencyCode: 'EGP',
      sourceAccountId: 'cash',
      destinationAccountId: 'cert-acct',
      reason: 'b',
      createdBy: 'user',
    );
    expect(a, isNot(b));
  });

  test('FP-PROF-1. Profit reversal fingerprint is deterministic', () {
    String build() => buildProfitReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalIncomeOperationId: 'op-profit',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 800,
      currencyCode: 'EGP',
      destinationAccountId: 'dst',
      reason: null,
      createdBy: 'user',
    );
    expect(build(), build());
    expect(
      build(),
      'revType=profitReverse|hh=hh1|cert=cert1|origOp=op-profit|'
      'date=2025-06-01|amt=800|cur=EGP|dst=dst|reason=|actor=user',
    );
  });

  test('FP-PROF-2. Profit reversal reason change fingerprint', () {
    final a = buildProfitReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalIncomeOperationId: 'op-profit',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 800,
      currencyCode: 'EGP',
      destinationAccountId: 'dst',
      reason: 'fix',
      createdBy: 'user',
    );
    final b = buildProfitReversalIdempotencyPayload(
      householdId: 'hh1',
      certificateId: 'cert1',
      originalIncomeOperationId: 'op-profit',
      effectiveDate: '2025-06-01',
      amountMinorUnits: 800,
      currencyCode: 'EGP',
      destinationAccountId: 'dst',
      reason: 'other',
      createdBy: 'user',
    );
    expect(a, isNot(b));
  });
}
