import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/data/certificate_repository.dart';
import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String _nowUtc() => DateTime.now().toUtc().toIso8601String();

String _localDate([Clock? clock]) {
  final n = clock?.now ?? DateTime.now();
  final y = n.year.toString().padLeft(4, '0');
  final m = n.month.toString().padLeft(2, '0');
  final d = n.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

bool _isSupportedCurrency(String code) {
  for (final c in Currency.values) {
    if (c.code == code) return true;
  }
  return false;
}

AppResult<T>? _validateFundingSource<T>(FinancialAccount? source) {
  if (source == null) return const AppNotFound();
  if (source.isArchived) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorAccountArchived',
    );
  }
  if (source.isProtected) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorCertificateSourceIsProtected',
    );
  }
  if (source.type == FinancialAccountType.goalReserve ||
      source.type == FinancialAccountType.certificate) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorCertificateAccountNotAllowedAsSource',
    );
  }
  return null;
}

// ── CreateCertificateUseCase ────────────────────────────────────────────────

final class CreateCertificateUseCase {
  const CreateCertificateUseCase({
    required CertificateRepository certRepository,
    required AccountRepository accountRepository,
  }) : _certs = certRepository,
       _accounts = accountRepository;

  final CertificateRepository _certs;
  final AccountRepository _accounts;

  Future<AppResult<SavingsCertificate>> execute({
    required String householdId,
    required String institutionName,
    required String currencyCode,
    required int principalMinorUnits,
    required String startDate,
    required String maturityDate,
    required String sourceAccountId,
    required String idempotencyKey,
    String? reference,
    String? note,
    int? annualRateBps,
    CertificateProfitFrequency? profitFrequency,
  }) async {
    if (institutionName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'institutionName',
        messageKey: 'errorCertificateInstitutionRequired',
      );
    }
    if (principalMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'principalMinorUnits',
        messageKey: 'errorCertificatePrincipalZero',
      );
    }
    if (!_isSupportedCurrency(currencyCode)) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCertificateCurrencyRequired',
      );
    }
    if (startDate.isEmpty || maturityDate.isEmpty) {
      return const AppValidationFailure(
        field: 'dates',
        messageKey: 'errorCertificateDatesRequired',
      );
    }
    if (maturityDate.compareTo(startDate) < 0) {
      return const AppValidationFailure(
        field: 'maturityDate',
        messageKey: 'errorCertificateMaturityBeforeStart',
      );
    }
    if (sourceAccountId.isEmpty) {
      return const AppValidationFailure(
        field: 'sourceAccountId',
        messageKey: 'errorCertificateSourceRequired',
      );
    }

    final source = await _accounts.findById(
      id: sourceAccountId,
      householdId: householdId,
    );
    final sourceError = _validateFundingSource<SavingsCertificate>(source);
    if (sourceError != null) return sourceError;
    if (source!.currencyCode != currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    final now = _nowUtc();
    final certId = _uuid.v4();
    final revisionId = _uuid.v4();
    final accountId = _uuid.v4();

    final revision = CertificateRevision(
      id: revisionId,
      certificateId: certId,
      householdId: householdId,
      institutionName: institutionName.trim(),
      reference: reference?.trim(),
      note: note?.trim(),
      annualRateBps: annualRateBps,
      profitFrequency: profitFrequency,
      createdAt: now,
      revisionReason: 'initial',
    );

    final account = FinancialAccount(
      id: accountId,
      householdId: householdId,
      name: 'Certificate: ${institutionName.trim()}',
      type: FinancialAccountType.certificate,
      ownerType: AccountOwnerType.household,
      fundPurpose: FundPurpose.certificate,
      currencyCode: currencyCode,
      isSpendable: false,
      isProtected: false,
      includeInNetWorth: true,
      includeInZakat: false,
      isArchived: false,
      displayOrder: 9999,
      createdAt: now,
      updatedAt: now,
      createdBy: 'system',
    );

    final certificate = SavingsCertificate(
      id: certId,
      householdId: householdId,
      certificateAccountId: accountId,
      currencyCode: currencyCode,
      originalPrincipalMinorUnits: principalMinorUnits,
      startDate: startDate,
      maturityDate: maturityDate,
      lifecycle: CertificateLifecycle.active,
      currentRevision: revision,
      createdAt: now,
      idempotencyKey: idempotencyKey,
      schemaVersion: 1,
    );

    final purchase = CertificatePurchaseFunding(
      operationId: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      sourceAccountId: sourceAccountId,
      amountMinorUnits: principalMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: startDate,
      description: 'Certificate purchase: ${institutionName.trim()}',
      eventId: _uuid.v4(),
      eventCreatedAt: now,
    );

    return _certs.createCertificate(
      certificate: certificate,
      initialRevision: revision,
      certificateAccount: account,
      purchase: purchase,
    );
  }
}

// ── GetCertificateProgressUseCase ───────────────────────────────────────────

final class GetCertificateProgressUseCase {
  const GetCertificateProgressUseCase(this._certs);

  final CertificateRepository _certs;

  Future<AppResult<CertificateProgress>> execute(String certificateId) async {
    final found = await _certs.findById(certificateId);
    if (found is! AppOk<SavingsCertificate?>) {
      return const AppPersistenceFailure();
    }
    final cert = found.value;
    if (cert == null) return const AppNotFound();

    final bal = await _certs.getPrincipalBalance(
      certificateAccountId: cert.certificateAccountId,
      householdId: cert.householdId,
    );
    if (bal is! AppOk<int>) return const AppPersistenceFailure();

    final events = await _certs.getEvents(certificateId);
    final revisions = await _certs.getRevisions(certificateId);
    if (events is! AppOk<List<CertificateEvent>> ||
        revisions is! AppOk<List<CertificateRevision>>) {
      return const AppPersistenceFailure();
    }

    final today = _localDate();
    final term = CertificateTermState.derive(
      lifecycle: cert.lifecycle,
      startDate: cert.startDate,
      maturityDate: cert.maturityDate,
      todayLocal: today,
      principalBalanceMinorUnits: bal.value,
    );

    return AppOk(
      CertificateProgress(
        certificate: cert,
        principalBalanceMinorUnits: bal.value,
        currencyCode: cert.currencyCode,
        termState: term,
        events: events.value,
        revisions: revisions.value,
        todayLocal: today,
      ),
    );
  }
}

// ── RecordCertificateProfitUseCase ──────────────────────────────────────────

final class RecordCertificateProfitUseCase {
  const RecordCertificateProfitUseCase({
    required CertificateRepository certRepository,
    required AccountRepository accountRepository,
  }) : _certs = certRepository,
       _accounts = accountRepository;

  final CertificateRepository _certs;
  final AccountRepository _accounts;

  Future<AppResult<CertificateProfitReceipt>> execute({
    required String certificateId,
    required String householdId,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String idempotencyKey,
    String? note,
    String? effectiveDate,
  }) async {
    final found = await _certs.findById(certificateId);
    if (found is! AppOk<SavingsCertificate?>) {
      return const AppPersistenceFailure();
    }
    final cert = found.value;
    if (cert == null || cert.householdId != householdId) {
      return const AppNotFound();
    }
    if (cert.lifecycle == CertificateLifecycle.archived) {
      return const AppValidationFailure(
        field: 'certificateId',
        messageKey: 'errorCertificateArchived',
      );
    }
    if (amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }

    final dest = await _accounts.findById(
      id: destinationAccountId,
      householdId: householdId,
    );
    if (dest == null) return const AppNotFound();
    if (dest.isArchived) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (dest.type == FinancialAccountType.goalReserve ||
        dest.type == FinancialAccountType.certificate) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorCertificateAccountNotAllowedAsDestination',
      );
    }
    if (dest.currencyCode != cert.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    final date =
        effectiveDate ??
        DateTime.now().toUtc().toIso8601String().substring(0, 10);

    return _certs.recordProfit(
      certificateId: certificateId,
      householdId: householdId,
      operationId: _uuid.v4(),
      eventId: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      destinationAccountId: destinationAccountId,
      amountMinorUnits: amountMinorUnits,
      currencyCode: cert.currencyCode,
      effectiveDate: date,
      createdBy: 'user',
      note: note,
    );
  }
}

// ── RedeemCertificateUseCase ────────────────────────────────────────────────

final class RedeemCertificateUseCase {
  const RedeemCertificateUseCase({
    required CertificateRepository certRepository,
    required AccountRepository accountRepository,
  }) : _certs = certRepository,
       _accounts = accountRepository;

  final CertificateRepository _certs;
  final AccountRepository _accounts;

  Future<AppResult<CertificateRedemptionSummary>> execute({
    required String certificateId,
    required String householdId,
    required String destinationAccountId,
    required int principalMinorUnits,
    required String idempotencyKey,
    int profitMinorUnits = 0,
    String? note,
  }) async {
    final found = await _certs.findById(certificateId);
    if (found is! AppOk<SavingsCertificate?>) {
      return const AppPersistenceFailure();
    }
    final cert = found.value;
    if (cert == null || cert.householdId != householdId) {
      return const AppNotFound();
    }

    final dest = await _accounts.findById(
      id: destinationAccountId,
      householdId: householdId,
    );
    if (dest == null) return const AppNotFound();
    if (dest.isArchived ||
        dest.type == FinancialAccountType.goalReserve ||
        dest.type == FinancialAccountType.certificate) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorCertificateAccountNotAllowedAsDestination',
      );
    }
    if (dest.currencyCode != cert.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    final today = _localDate();
    final date = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    CertificateMaturityProfitParams? profit;
    if (profitMinorUnits > 0) {
      profit = CertificateMaturityProfitParams(
        operationId: _uuid.v4(),
        idempotencyKey: 'profit-$idempotencyKey',
        destinationAccountId: destinationAccountId,
        amountMinorUnits: profitMinorUnits,
        currencyCode: cert.currencyCode,
        effectiveDate: date,
        description: 'Maturity profit: ${cert.institutionName}',
      );
    }

    return _certs.redeem(
      certificateId: certificateId,
      householdId: householdId,
      principalOperationId: _uuid.v4(),
      eventId: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      destinationAccountId: destinationAccountId,
      principalMinorUnits: principalMinorUnits,
      effectiveDate: date,
      createdBy: 'user',
      todayLocal: today,
      maturityProfit: profit,
      note: note,
    );
  }
}

// ── Archive / Restore ───────────────────────────────────────────────────────

final class ArchiveCertificateUseCase {
  const ArchiveCertificateUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<void>> execute({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) => _certs.archive(
    certificateId: certificateId,
    householdId: householdId,
    idempotencyKey: idempotencyKey,
  );
}

final class RestoreCertificateUseCase {
  const RestoreCertificateUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<void>> execute({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) => _certs.restore(
    certificateId: certificateId,
    householdId: householdId,
    idempotencyKey: idempotencyKey,
  );
}

// ── ReviseCertificateDefinitionUseCase ──────────────────────────────────────

final class ReviseCertificateDefinitionUseCase {
  const ReviseCertificateDefinitionUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<CertificateRevision>> execute({
    required String certificateId,
    required String householdId,
    required String institutionName,
    required String revisionReason,
    String? reference,
    String? note,
    int? annualRateBps,
    CertificateProfitFrequency? profitFrequency,
  }) async {
    if (institutionName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'institutionName',
        messageKey: 'errorCertificateInstitutionRequired',
      );
    }
    final found = await _certs.findById(certificateId);
    if (found is! AppOk<SavingsCertificate?>) {
      return const AppPersistenceFailure();
    }
    final cert = found.value;
    if (cert == null || cert.householdId != householdId) {
      return const AppNotFound();
    }

    final revision = CertificateRevision(
      id: _uuid.v4(),
      certificateId: certificateId,
      householdId: householdId,
      institutionName: institutionName.trim(),
      reference: reference ?? cert.reference,
      note: note ?? cert.note,
      annualRateBps: annualRateBps ?? cert.annualRateBps,
      profitFrequency: profitFrequency ?? cert.profitFrequency,
      createdAt: _nowUtc(),
      revisionReason: revisionReason,
    );
    return _certs.reviseDefinition(revision: revision);
  }
}

// ── Reversals ───────────────────────────────────────────────────────────────

final class ReverseCertificatePurchaseUseCase {
  const ReverseCertificatePurchaseUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<void>> execute({
    required String certificateId,
    required String householdId,
    required String idempotencyKey,
    String? reason,
  }) {
    final date = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _certs.reversePurchase(
      certificateId: certificateId,
      householdId: householdId,
      reversalOperationId: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      effectiveDate: date,
      createdBy: 'user',
      reason: reason,
    );
  }
}

final class ReverseCertificateProfitUseCase {
  const ReverseCertificateProfitUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<void>> execute({
    required String certificateId,
    required String householdId,
    required String originalProfitOperationId,
    required String idempotencyKey,
    String? reason,
  }) {
    final date = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _certs.reverseProfit(
      certificateId: certificateId,
      householdId: householdId,
      originalIncomeOperationId: originalProfitOperationId,
      reversalOperationId: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      effectiveDate: date,
      createdBy: 'user',
      reason: reason,
    );
  }
}

final class ReverseCertificateRedemptionUseCase {
  const ReverseCertificateRedemptionUseCase(this._certs);
  final CertificateRepository _certs;

  Future<AppResult<void>> execute({
    required String certificateId,
    required String householdId,
  }) => _certs.reverseRedemption(
    certificateId: certificateId,
    householdId: householdId,
  );
}
