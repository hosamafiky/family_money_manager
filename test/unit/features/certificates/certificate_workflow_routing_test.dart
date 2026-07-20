/// Phase 6A.1 — profit-only vs redemption use-case routing (application fakes).
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/certificate_repository.dart';
import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingCertRepository implements CertificateRepository {
  int profitCalls = 0;
  int redeemCalls = 0;

  SavingsCertificate get _cert => const SavingsCertificate(
    id: 'c1',
    householdId: 'hh',
    certificateAccountId: 'cert-acc',
    currencyCode: 'EGP',
    originalPrincipalMinorUnits: 10000,
    startDate: '2019-01-01',
    maturityDate: '2020-01-01',
    lifecycle: CertificateLifecycle.active,
    currentRevision: CertificateRevision(
      id: 'r1',
      certificateId: 'c1',
      householdId: 'hh',
      institutionName: 'Bank',
      createdAt: '2019-01-01T00:00:00Z',
      revisionReason: 'initial',
    ),
    createdAt: '2019-01-01T00:00:00Z',
    idempotencyKey: 'ik',
    schemaVersion: 1,
  );

  @override
  Future<AppResult<SavingsCertificate>> createCertificate({
    required SavingsCertificate certificate,
    required CertificateRevision initialRevision,
    required FinancialAccount certificateAccount,
    required CertificatePurchaseFunding purchase,
  }) async => AppOk(certificate);

  @override
  Future<AppResult<CertificateProfitReceipt>> recordProfit({
    required String certificateId,
    required String householdId,
    required String operationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? note,
  }) async {
    profitCalls++;
    return AppOk(
      CertificateProfitReceipt(
        event: CertificateEvent(
          id: eventId,
          certificateId: certificateId,
          householdId: householdId,
          eventType: CertificateEventType.profitReceived,
          relatedOperationId: operationId,
          amountMinorUnits: amountMinorUnits,
          currencyCode: currencyCode,
          idempotencyKey: idempotencyKey,
          effectiveAt: effectiveDate,
          createdAt: effectiveDate,
        ),
        incomeOperationId: operationId,
        destinationAccountId: destinationAccountId,
        amountMinorUnits: amountMinorUnits,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  Future<AppResult<CertificateRedemptionSummary>> redeem({
    required String certificateId,
    required String householdId,
    required String principalOperationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int principalMinorUnits,
    required String effectiveDate,
    required String createdBy,
    required String todayLocal,
    CertificateMaturityProfitParams? maturityProfit,
    String? note,
  }) async {
    redeemCalls++;
    return AppOk(
      CertificateRedemptionSummary(
        certificate: _cert,
        principalMinorUnits: principalMinorUnits,
        profitMinorUnits: maturityProfit?.amountMinorUnits ?? 0,
        destinationAccountId: destinationAccountId,
        currencyCode: 'EGP',
        principalOperationId: principalOperationId,
        profitOperationId: maturityProfit?.operationId,
        event: CertificateEvent(
          id: eventId,
          certificateId: certificateId,
          householdId: householdId,
          eventType: CertificateEventType.redeemed,
          relatedOperationId: principalOperationId,
          amountMinorUnits: principalMinorUnits,
          currencyCode: 'EGP',
          idempotencyKey: idempotencyKey,
          effectiveAt: effectiveDate,
          createdAt: effectiveDate,
        ),
      ),
    );
  }

  @override
  Future<AppResult<SavingsCertificate?>> findById(String certificateId) async =>
      AppOk(_cert);

  @override
  Future<AppResult<List<SavingsCertificate>>> listCertificates({
    required String householdId,
    bool includeArchived = false,
  }) async => const AppOk([]);

  @override
  Future<AppResult<int>> getPrincipalBalance({
    required String certificateAccountId,
    required String householdId,
  }) async => const AppOk(10000);

  @override
  Future<AppResult<List<CertificateEvent>>> getEvents(
    String certificateId,
  ) async => const AppOk([]);

  @override
  Future<AppResult<List<CertificateRevision>>> getRevisions(
    String certificateId,
  ) async => const AppOk([]);

  @override
  Future<AppResult<void>> archive({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) async => const AppOk(null);

  @override
  Future<AppResult<void>> restore({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) async => const AppOk(null);

  @override
  Future<AppResult<CertificateRevision>> reviseDefinition({
    required CertificateRevision revision,
  }) async => AppOk(revision);

  @override
  Future<AppResult<void>> reversePurchase({
    required String certificateId,
    required String householdId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  }) async => const AppOk(null);

  @override
  Future<AppResult<void>> reverseProfit({
    required String certificateId,
    required String householdId,
    required String originalIncomeOperationId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  }) async => const AppOk(null);

  @override
  Future<AppResult<void>> reverseRedemption({
    required String certificateId,
    required String householdId,
  }) async => const AppValidationFailure(
    field: 'redemption',
    messageKey: 'errorCertificateRedemptionReversalNotSupported',
  );
}

class _FakeAccounts implements AccountRepository {
  FinancialAccount _acct(String id, String householdId) => FinancialAccount(
    id: id,
    householdId: householdId,
    name: id,
    type: FinancialAccountType.bankAccount,
    ownerType: AccountOwnerType.user,
    fundPurpose: FundPurpose.available,
    currencyCode: 'EGP',
    isSpendable: true,
    isProtected: false,
    includeInNetWorth: true,
    includeInZakat: false,
    isArchived: false,
    displayOrder: 0,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
    createdBy: 'test',
  );

  @override
  Future<FinancialAccount> createAccount(CreateAccountParams params) async =>
      _acct(params.id, params.householdId);

  @override
  Future<FinancialAccount?> findByIdempotencyKey({
    required String householdId,
    required String idempotencyKey,
  }) async => null;

  @override
  Future<FinancialAccount?> findById({
    required String id,
    required String householdId,
  }) async => _acct(id, householdId);

  @override
  Future<List<FinancialAccount>> findByHousehold({
    required String householdId,
    bool includeArchived = false,
  }) async => [];

  @override
  Future<bool> hasOpeningBalance({
    required String accountId,
    required String householdId,
  }) async => false;

  @override
  Future<FinancialAccount> archiveAccount({
    required String id,
    required String householdId,
    required DateTime archivedAt,
    required String updatedAt,
  }) async => _acct(id, householdId);

  @override
  Future<FinancialAccount> updateAccount({
    required String id,
    required String householdId,
    String? name,
    bool? isSpendable,
    bool? isProtected,
    bool? includeInNetWorth,
    bool? includeInZakat,
    int? displayOrder,
    String? notes,
    Map<String, dynamic>? metadata,
    required String updatedAt,
  }) async => _acct(id, householdId);
}

void main() {
  test(
    'APP-WF-1. RecordCertificateProfitUseCase calls recordProfit only',
    () async {
      final repo = _CountingCertRepository();
      final uc = RecordCertificateProfitUseCase(
        certRepository: repo,
        accountRepository: _FakeAccounts(),
      );
      final result = await uc.execute(
        certificateId: 'c1',
        householdId: 'hh',
        destinationAccountId: 'dst',
        amountMinorUnits: 500,
        idempotencyKey: 'p1',
      );
      expect(result, isA<AppOk<CertificateProfitReceipt>>());
      expect(repo.profitCalls, 1);
      expect(repo.redeemCalls, 0);
    },
  );

  test('APP-WF-2. RedeemCertificateUseCase calls redeem only', () async {
    final repo = _CountingCertRepository();
    final uc = RedeemCertificateUseCase(
      certRepository: repo,
      accountRepository: _FakeAccounts(),
    );
    final result = await uc.execute(
      certificateId: 'c1',
      householdId: 'hh',
      destinationAccountId: 'dst',
      principalMinorUnits: 10000,
      profitMinorUnits: 250,
      idempotencyKey: 'r1',
    );
    expect(result, isA<AppOk<CertificateRedemptionSummary>>());
    expect(repo.redeemCalls, 1);
    expect(repo.profitCalls, 0);
  });

  test('APP-WF-3. Reverse redemption rejected at use case', () async {
    final repo = _CountingCertRepository();
    final uc = ReverseCertificateRedemptionUseCase(repo);
    final result = await uc.execute(certificateId: 'c1', householdId: 'hh');
    expect(result, isA<AppValidationFailure<void>>());
  });
}
