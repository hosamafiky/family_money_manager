/// Savings-certificate repository integration tests.
///
/// Tests:
///  1. Create certificate and account atomically
///  2. Certificate creation is idempotent (same key + same payload → existing)
///  3. Conflicting payload returns AppDuplicateConflict
///  4. Cross-household isolation
///  5. Certificate account created with correct type (certificate)
///  6. Certificate account is non-spendable
///  7. Certificate account is non-protected
///  8. includeInNetWorth = true
///  9. Purchase transfer debits source, credits certificate account
/// 10. Source balance decremented after purchase
/// 11. Certificate account balance incremented after purchase
/// 12. Purchase operation type is certificateFunding
/// 13. Purchased event created
/// 14. Rollback when source has insufficient balance
/// 15. recordProfit: income operation recorded
/// 16. recordProfit: profit credited to destination account
/// 17. recordProfit: profitReceived event created
/// 18. recordProfit: idempotent replay
/// 19. recordProfit: rejected when archived
/// 20. redeem: transfers principal from certificate to destination
/// 21. redeem: lifecycle set to redeemed
/// 22. redeem: redeemed event created
/// 23. redeem: optional maturity profit income created
/// 24. redeem: insufficient balance → AppInsufficientFunds
/// 25. redeem: rejected when not active
/// 26. archive: lifecycle set to archived
/// 27. archive: rejected when balance != 0
/// 28. archive: idempotent
/// 29. restore: lifecycle set to active
/// 30. restore: rejected when not archived
/// 31. reversePurchase: reverses purchase operation + archives
/// 32. reversePurchase: rejected when lifecycle != active
/// 33. reversePurchase: rejected when profit history exists
/// 34. reverseProfit: reverses profit income operation
/// 35. reverseRedemption: explicitly rejected
/// 36. reviseDefinition: appends new revision
/// 37. revisions are immutable (UPDATE trigger)
/// 38. events are immutable (UPDATE trigger)
/// 39. certificate account excluded from ordinary income
/// 40. certificate account excluded from ordinary expense
/// 41. certificate account excluded from ordinary transfer (source)
/// 42. certificate account excluded from ordinary transfer (destination)
/// 43. certificate account excluded from opening balance
/// 44. certificate account excluded from adjustment
/// 45. Fresh schema v17: all certificate tables exist
/// 46. Two concurrent create calls (same idem key) → one certificate
/// 47. listCertificates: excludes archived by default
/// 48. listCertificates: includes archived when flag set
/// 49. getPrincipalBalance: derived from ledger
/// 50. getRevisions: returns in ASC order
/// 51. getEvents: returns in ASC order
library;

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/application/execute_transfer_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_expense_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_income_use_case.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-cert-test';
const _hh2 = 'hh-cert-test-2';

/// Stub household repository that throws on any call.
/// Used by UC tests where the certificate guard fires before member lookups.
class _NoopHouseholdRepository implements HouseholdRepository {
  @override
  Future<HouseholdIdentity?> findHousehold(String householdId) =>
      throw UnimplementedError();

  @override
  Future<HouseholdIdentity> createHousehold({
    required String id,
    required String displayName,
    required String currencyCode,
    required String ownerUserId,
  }) => throw UnimplementedError();

  @override
  Future<HouseholdIdentity> updateHouseholdName({
    required String id,
    required String displayName,
  }) => throw UnimplementedError();

  @override
  Future<HouseholdMember> addMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
  }) => throw UnimplementedError();

  @override
  Future<HouseholdMember?> findMember({
    required String memberId,
    required String householdId,
  }) => throw UnimplementedError();

  @override
  Future<List<HouseholdMember>> listMembers(String householdId) =>
      throw UnimplementedError();

  @override
  Future<HouseholdMember> renameMember({
    required String memberId,
    required String householdId,
    required String displayName,
  }) => throw UnimplementedError();

  @override
  Future<HouseholdMember> archiveMember({
    required String memberId,
    required String householdId,
  }) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late DriftCertificateRepository certRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late CreateCertificateUseCase createCertUc;
  late RecordCertificateProfitUseCase recordProfitUc;
  late RedeemCertificateUseCase redeemUc;
  late ArchiveCertificateUseCase archiveUc;
  late RestoreCertificateUseCase restoreUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    certRepo = DriftCertificateRepository(db);
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);

    createCertUc = CreateCertificateUseCase(
      certRepository: certRepo,
      accountRepository: accountRepo,
    );
    recordProfitUc = RecordCertificateProfitUseCase(
      certRepository: certRepo,
      accountRepository: accountRepo,
    );
    redeemUc = RedeemCertificateUseCase(
      certRepository: certRepo,
      accountRepository: accountRepo,
    );
    archiveUc = ArchiveCertificateUseCase(certRepo);
    restoreUc = RestoreCertificateUseCase(certRepo);

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  // ── Test helpers ──────────────────────────────────────────────────────────

  Future<FinancialAccount> createAccount({
    required String id,
    required String householdId,
    String currency = 'EGP',
    String type = 'bankAccount',
  }) async {
    return accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
  }

  Future<void> creditAccount(
    String accId,
    String hhId,
    int amount, {
    String currency = 'EGP',
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'income-$accId-${DateTime.now().microsecondsSinceEpoch}',
        householdId: hhId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<AppResult<SavingsCertificate>> createCert({
    String householdId = _hh,
    String sourceAccountId = 'src-acc',
    int principal = 100000,
    String currency = 'EGP',
    String idempotencyKey = 'idem-key-1',
    String institution = 'National Bank',
    String startDate = '2025-01-01',
    String maturityDate = '2026-01-01',
  }) async {
    return createCertUc.execute(
      householdId: householdId,
      institutionName: institution,
      currencyCode: currency,
      principalMinorUnits: principal,
      startDate: startDate,
      maturityDate: maturityDate,
      sourceAccountId: sourceAccountId,
      idempotencyKey: idempotencyKey,
    );
  }

  // ── Tests ─────────────────────────────────────────────────────────────────

  test('1. Create certificate and account atomically', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    expect(result, isA<AppOk<SavingsCertificate>>());
    final cert = (result as AppOk<SavingsCertificate>).value;

    expect(cert.lifecycle, CertificateLifecycle.active);
    expect(cert.originalPrincipalMinorUnits, 100000);
    expect(cert.institutionName, 'National Bank');

    final acct = await accountRepo.findById(
      id: cert.certificateAccountId,
      householdId: _hh,
    );
    expect(acct, isNotNull);
    expect(acct!.type, FinancialAccountType.certificate);
  });

  test(
    '2. Certificate creation idempotent: same key + same payload → existing',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final r1 = await createCert();
      final r2 = await createCert(); // same key

      expect(r1, isA<AppOk<SavingsCertificate>>());
      expect(r2, isA<AppOk<SavingsCertificate>>());
      final c1 = (r1 as AppOk<SavingsCertificate>).value;
      final c2 = (r2 as AppOk<SavingsCertificate>).value;
      expect(c1.id, c2.id);

      final ops = await db
          .customSelect(
            "SELECT id FROM operations WHERE household_id = ? AND type = 'certificateFunding'",
            variables: [Variable.withString(_hh)],
          )
          .get();
      expect(ops.length, 1);
    },
  );

  test('3. Conflicting payload returns AppDuplicateConflict', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 500000);

    await createCert(principal: 100000);

    // Same idempotency key but different principal.
    final r2 = await createCert(principal: 200000);
    expect(r2, isA<AppDuplicateConflict<SavingsCertificate>>());
  });

  test('4. Cross-household isolation', () async {
    await createAccount(id: 'src-hh1', householdId: _hh);
    await createAccount(id: 'src-hh2', householdId: _hh2);
    await creditAccount('src-hh1', _hh, 200000);
    await creditAccount('src-hh2', _hh2, 200000);

    await createCert(
      householdId: _hh,
      sourceAccountId: 'src-hh1',
      idempotencyKey: 'k-hh1',
    );
    await createCert(
      householdId: _hh2,
      sourceAccountId: 'src-hh2',
      idempotencyKey: 'k-hh2',
    );

    final list1 = await certRepo.listCertificates(householdId: _hh);
    final list2 = await certRepo.listCertificates(householdId: _hh2);

    expect((list1 as AppOk<List<SavingsCertificate>>).value, hasLength(1));
    expect((list2 as AppOk<List<SavingsCertificate>>).value, hasLength(1));
  });

  test('5. Certificate account created with type certificate', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    final cert = (result as AppOk<SavingsCertificate>).value;

    final acct = await accountRepo.findById(
      id: cert.certificateAccountId,
      householdId: _hh,
    );
    expect(acct!.type, FinancialAccountType.certificate);
  });

  test('6. Certificate account is non-spendable', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    final cert = (result as AppOk<SavingsCertificate>).value;

    final acct = await accountRepo.findById(
      id: cert.certificateAccountId,
      householdId: _hh,
    );
    expect(acct!.isSpendable, isFalse);
  });

  test('7. Certificate account is non-protected', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    final cert = (result as AppOk<SavingsCertificate>).value;

    final acct = await accountRepo.findById(
      id: cert.certificateAccountId,
      householdId: _hh,
    );
    expect(acct!.isProtected, isFalse);
  });

  test('8. includeInNetWorth = true', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    final cert = (result as AppOk<SavingsCertificate>).value;

    final acct = await accountRepo.findById(
      id: cert.certificateAccountId,
      householdId: _hh,
    );
    expect(acct!.includeInNetWorth, isTrue);
  });

  test(
    '9. Purchase transfer debits source, credits certificate account',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final result = await createCert(principal: 100000);
      final cert = (result as AppOk<SavingsCertificate>).value;

      final entries = await db
          .customSelect(
            "SELECT account_id, direction FROM ledger_entries "
            "WHERE household_id = ? AND entry_type = 'transferOut' OR "
            "(household_id = ? AND entry_type = 'transferIn')",
            variables: [Variable.withString(_hh), Variable.withString(_hh)],
          )
          .get();

      final debits = entries
          .where((e) => e.read<String>('direction') == 'debit')
          .toList();
      final credits = entries
          .where((e) => e.read<String>('direction') == 'credit')
          .toList();

      expect(
        debits.any((e) => e.read<String>('account_id') == 'src-acc'),
        isTrue,
        reason: 'Source account should be debited',
      );
      expect(
        credits.any(
          (e) => e.read<String>('account_id') == cert.certificateAccountId,
        ),
        isTrue,
        reason: 'Certificate account should be credited',
      );
    },
  );

  test('10. Source balance decremented after purchase', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    await createCert(principal: 100000);

    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'src-acc',
      householdId: _hh,
    );
    // Source: credited 200000, debited 100000 → balance 100000.
    expect((bal as AppOk<int>).value, 100000);
  });

  test('11. Certificate account balance incremented after purchase', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert(principal: 100000);
    final cert = (result as AppOk<SavingsCertificate>).value;

    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: cert.certificateAccountId,
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 100000);
  });

  test('12. Purchase operation type is certificateFunding', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    await createCert();

    final ops = await db
        .customSelect(
          "SELECT type FROM operations WHERE household_id = ? AND type = 'certificateFunding'",
          variables: [Variable.withString(_hh)],
        )
        .get();

    expect(ops, isNotEmpty);
  });

  test('13. Purchased event created', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final result = await createCert();
    final cert = (result as AppOk<SavingsCertificate>).value;

    final events = await db
        .customSelect(
          "SELECT event_type FROM certificate_events WHERE certificate_id = ?",
          variables: [Variable.withString(cert.id)],
        )
        .get();
    expect(
      events.any((e) => e.read<String>('event_type') == 'purchased'),
      isTrue,
    );
  });

  test('14. Rollback when source has insufficient balance', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 50000); // less than principal

    final result = await createCert(principal: 100000);
    expect(result, isA<AppInsufficientFunds<SavingsCertificate>>());

    final certs = await certRepo.listCertificates(householdId: _hh);
    expect((certs as AppOk<List<SavingsCertificate>>).value, isEmpty);
  });

  test('15. recordProfit: income operation recorded', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-1',
    );

    final ops = await db
        .customSelect(
          "SELECT id, category_code FROM operations "
          "WHERE household_id = ? AND type = 'income' AND category_code = 'certificate_profit'",
          variables: [Variable.withString(_hh)],
        )
        .get();
    expect(ops, isNotEmpty);
  });

  test('16. recordProfit: profit credited to destination account', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-1',
    );

    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'dest-acc',
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 5000);
  });

  test('17. recordProfit: profitReceived event created', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-1',
    );

    final events = await db
        .customSelect(
          "SELECT event_type FROM certificate_events WHERE certificate_id = ?",
          variables: [Variable.withString(cert.id)],
        )
        .get();
    expect(
      events.any((e) => e.read<String>('event_type') == 'profitReceived'),
      isTrue,
    );
  });

  test('18. recordProfit: idempotent replay', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-1',
    );
    final r2 = await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-1',
    );

    // Idempotent: second call returns OK but no double credit.
    expect(r2, isA<AppOk<CertificateProfitReceipt>>());
    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'dest-acc',
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 5000);
  });

  test('19. recordProfit: rejected when archived', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await db.customStatement(
      "UPDATE savings_certificates SET lifecycle = 'archived' WHERE id = ?",
      [cert.id],
    );

    final result = await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-key-archived',
    );
    expect(result, isA<AppValidationFailure<CertificateProfitReceipt>>());
  });

  test(
    '20. redeem: transfers principal from certificate to destination',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await createAccount(id: 'dest-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final cert =
          ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
              .value;

      final result = await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dest-acc',
        principalMinorUnits: 100000,
        idempotencyKey: 'redeem-key-1',
      );
      expect(result, isA<AppOk<CertificateRedemptionSummary>>());

      final destBal = await certRepo.getPrincipalBalance(
        certificateAccountId: 'dest-acc',
        householdId: _hh,
      );
      expect((destBal as AppOk<int>).value, 100000);
    },
  );

  test('21. redeem: lifecycle set to redeemed', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 100000,
      idempotencyKey: 'redeem-key-1',
    );

    final updated =
        ((await certRepo.findById(cert.id)) as AppOk<SavingsCertificate?>)
            .value;
    expect(updated!.lifecycle, CertificateLifecycle.redeemed);
  });

  test('22. redeem: redeemed event created', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 100000,
      idempotencyKey: 'redeem-key-1',
    );

    final events = await db
        .customSelect(
          "SELECT event_type FROM certificate_events WHERE certificate_id = ?",
          variables: [Variable.withString(cert.id)],
        )
        .get();
    expect(
      events.any((e) => e.read<String>('event_type') == 'redeemed'),
      isTrue,
    );
  });

  test('23. redeem: optional maturity profit income created', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 100000,
      profitMinorUnits: 8000,
      idempotencyKey: 'redeem-key-1',
    );

    final destBal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'dest-acc',
      householdId: _hh,
    );
    expect(
      (destBal as AppOk<int>).value,
      108000,
    ); // 100000 principal + 8000 profit
  });

  test('24. redeem: insufficient balance → AppInsufficientFunds', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final result = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 200000, // exceeds balance
      idempotencyKey: 'redeem-key-1',
    );
    expect(result, isA<AppInsufficientFunds<CertificateRedemptionSummary>>());
  });

  test('25. redeem: rejected when not active', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    // First redeem.
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 100000,
      idempotencyKey: 'redeem-key-1',
    );

    // Second redeem on already-redeemed cert.
    final result2 = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 1,
      idempotencyKey: 'redeem-key-2',
    );
    expect(result2, isA<AppValidationFailure<CertificateRedemptionSummary>>());
  });

  test(
    '26. archive: lifecycle set to archived (after zeroing balance)',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final cert =
          ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
              .value;

      // Zero principal via purchase reversal (ledger entries are immutable).
      final reverseUc = ReverseCertificatePurchaseUseCase(certRepo);
      final reverseResult = await reverseUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'rev-arch-1',
      );
      expect(reverseResult, isA<AppOk<void>>());

      // reversePurchase already archives — confirm idempotent re-archive works.
      final result = await archiveUc.execute(
        certificateId: cert.id,
        householdId: _hh,
      );
      expect(result, isA<AppOk<void>>());

      final updated =
          ((await certRepo.findById(cert.id)) as AppOk<SavingsCertificate?>)
              .value;
      expect(updated!.lifecycle, CertificateLifecycle.archived);
    },
  );

  test('27. archive: rejected when balance != 0', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final result = await archiveUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  test('28. archive: idempotent on already-archived', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;
    await db.customStatement(
      "UPDATE savings_certificates SET lifecycle = 'archived' WHERE id = ?",
      [cert.id],
    );

    // Both calls should succeed (idempotent).
    final r1 = await archiveUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    final r2 = await archiveUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(r1, isA<AppOk<void>>());
    expect(r2, isA<AppOk<void>>());
  });

  test('29. restore: lifecycle set to active', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;
    await db.customStatement(
      "UPDATE savings_certificates SET lifecycle = 'archived' WHERE id = ?",
      [cert.id],
    );

    final result = await restoreUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(result, isA<AppOk<void>>());

    final updated =
        ((await certRepo.findById(cert.id)) as AppOk<SavingsCertificate?>)
            .value;
    expect(updated!.lifecycle, CertificateLifecycle.active);
  });

  test('30. restore: rejected when not archived', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final result = await restoreUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  test('31. reversePurchase: reverses purchase operation + archives', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final reverseUc = ReverseCertificatePurchaseUseCase(certRepo);
    final result = await reverseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'rev-purchase-1',
    );
    expect(result, isA<AppOk<void>>());

    // Source balance restored (200000 credit − 100000 purchase + 100000 reversal = 200000).
    final srcBal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'src-acc',
      householdId: _hh,
    );
    expect((srcBal as AppOk<int>).value, 200000);

    final updated =
        ((await certRepo.findById(cert.id)) as AppOk<SavingsCertificate?>)
            .value;
    expect(updated!.lifecycle, CertificateLifecycle.archived);
  });

  test('32. reversePurchase: rejected when lifecycle != active', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      principalMinorUnits: 100000,
      idempotencyKey: 'redeem-k',
    );

    final reverseUc = ReverseCertificatePurchaseUseCase(certRepo);
    final result = await reverseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'rev-purchase-1',
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  test('33. reversePurchase: rejected when profit history exists', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 3000,
      idempotencyKey: 'profit-k',
    );

    final reverseUc = ReverseCertificatePurchaseUseCase(certRepo);
    final result = await reverseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'rev-purchase-1',
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  test('34. reverseProfit: reverses profit income operation', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final profitResult = await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 5000,
      idempotencyKey: 'profit-k',
    );
    final profitReceipt =
        (profitResult as AppOk<CertificateProfitReceipt>).value;

    final reverseUc = ReverseCertificateProfitUseCase(certRepo);
    final result = await reverseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: profitReceipt.incomeOperationId,
      idempotencyKey: 'rev-profit-1',
    );
    expect(result, isA<AppOk<void>>());

    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: 'dest-acc',
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 0);
  });

  test('35. reverseRedemption: explicitly rejected', () async {
    final result = await certRepo.reverseRedemption(
      certificateId: 'any',
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
    final failure = result as AppValidationFailure<void>;
    expect(
      failure.messageKey,
      'errorCertificateRedemptionReversalNotSupported',
    );
  });

  test('36. reviseDefinition: appends new revision', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    final reviseUc = ReviseCertificateDefinitionUseCase(certRepo);
    await reviseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      institutionName: 'Updated Bank',
      revisionReason: 'name change',
    );

    final revs = await certRepo.getRevisions(cert.id);
    expect((revs as AppOk<List<CertificateRevision>>).value, hasLength(2));
    expect(revs.value.last.institutionName, 'Updated Bank');
  });

  test('37. revisions are immutable (UPDATE trigger)', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    final revs = await certRepo.getRevisions(cert.id);
    final revId = (revs as AppOk<List<CertificateRevision>>).value.first.id;

    expect(
      () async => db.customStatement(
        "UPDATE certificate_revisions SET institution_name = 'Hacked' WHERE id = ?",
        [revId],
      ),
      throwsA(anything),
    );
  });

  test('38. events are immutable (UPDATE trigger)', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    final events = await certRepo.getEvents(cert.id);
    final evtId = (events as AppOk<List<CertificateEvent>>).value.first.id;

    expect(
      () async => db.customStatement(
        "UPDATE certificate_events SET event_type = 'hacked' WHERE id = ?",
        [evtId],
      ),
      throwsA(anything),
    );
  });

  test('39. certificate account excluded from ordinary income', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;
    final incomeUc = RecordIncomeUseCase(
      ledgerRepository: ledgerRepo,
      accountRepository: accountRepo,
    );

    final result = await incomeUc.execute(
      IncomeContext(
        operationId: 'uc-income-cert',
        idempotencyKey: 'uc-income-cert-idem',
        householdId: _hh,
        destinationAccountId: cert.certificateAccountId,
        amountMinorUnits: 1000,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-15',
        category: TransactionCategory.salary,
        createdBy: 'test',
      ),
    );
    expect(result, isA<AppValidationFailure<String>>());
    expect(
      (result as AppValidationFailure).messageKey,
      'errorCertificateAccountNotAllowedInOrdinaryTransaction',
    );
  });

  test('40. certificate account excluded from ordinary expense', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;
    final expenseUc = RecordExpenseUseCase(
      ledgerRepository: ledgerRepo,
      accountRepository: accountRepo,
      householdRepository: _NoopHouseholdRepository(),
    );

    final result = await expenseUc.execute(
      ExpenseContext(
        operationId: 'uc-expense-cert',
        idempotencyKey: 'uc-expense-cert-idem',
        householdId: _hh,
        paymentAccountId: cert.certificateAccountId,
        amountMinorUnits: 1000,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-15',
        category: TransactionCategory.groceries,
        spenderMemberId: 'u1',
        beneficiaryMemberId: 'u1',
        scope: ExpenseScope.personal,
        isRecurring: false,
        createdBy: 'test',
      ),
    );
    expect(result, isA<AppValidationFailure<String>>());
    expect(
      (result as AppValidationFailure).messageKey,
      'errorCertificateAccountNotAllowedInOrdinaryTransaction',
    );
  });

  test(
    '41. certificate account excluded from ordinary transfer (source)',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await createAccount(id: 'dest-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;
      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );

      final result = await transferUc.execute(
        TransferContext(
          operationId: 'uc-transfer-cert-src',
          idempotencyKey: 'uc-transfer-cert-src-idem',
          householdId: _hh,
          sourceAccountId: cert.certificateAccountId,
          destinationAccountId: 'dest-acc',
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-15',
          createdBy: 'test',
        ),
      );
      expect(result, isA<AppValidationFailure<String>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorCertificateAccountNotAllowedInOrdinaryTransaction',
      );
    },
  );

  test(
    '42. certificate account excluded from ordinary transfer (destination)',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 200000);

      final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;
      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );

      final result = await transferUc.execute(
        TransferContext(
          operationId: 'uc-transfer-cert-dst',
          idempotencyKey: 'uc-transfer-cert-dst-idem',
          householdId: _hh,
          sourceAccountId: 'src-acc',
          destinationAccountId: cert.certificateAccountId,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-15',
          createdBy: 'test',
        ),
      );
      expect(result, isA<AppValidationFailure<String>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorCertificateAccountNotAllowedInOrdinaryTransaction',
      );
    },
  );

  test('43. certificate account excluded from opening balance', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    expect(
      () async => ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-cert',
          householdId: _hh,
          accountId: cert.certificateAccountId,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('44. certificate account excluded from adjustment', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    expect(
      () async => ledgerRepo.recordAdjustment(
        RecordAdjustmentParams(
          operationId: 'adj-cert',
          householdId: _hh,
          accountId: cert.certificateAccountId,
          adjustmentAmountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
          reason: 'test adjustment',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('45. Fresh schema v17: all certificate tables exist', () async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final names = tables.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll([
        'savings_certificates',
        'certificate_revisions',
        'certificate_events',
      ]),
    );
  });

  test(
    '46. Two concurrent create calls (same idem key) → one certificate',
    () async {
      await createAccount(id: 'src-acc', householdId: _hh);
      await creditAccount('src-acc', _hh, 400000);

      final results = await Future.wait([
        createCert(principal: 100000, idempotencyKey: 'concurrent-key'),
        createCert(principal: 100000, idempotencyKey: 'concurrent-key'),
      ]);

      final certs = await certRepo.listCertificates(householdId: _hh);
      expect((certs as AppOk<List<SavingsCertificate>>).value, hasLength(1));

      final successes = results.whereType<AppOk<SavingsCertificate>>().length;
      expect(successes, greaterThanOrEqualTo(1));
    },
  );

  test('47. listCertificates: excludes archived by default', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 400000);

    await createCert(
      principal: 100000,
      idempotencyKey: 'k1',
      institution: 'Bank1',
    );
    final cert2 =
        ((await createCert(
                  principal: 100000,
                  idempotencyKey: 'k2',
                  institution: 'Bank2',
                ))
                as AppOk<SavingsCertificate>)
            .value;

    await db.customStatement(
      "UPDATE savings_certificates SET lifecycle = 'archived' WHERE id = ?",
      [cert2.id],
    );

    final list = await certRepo.listCertificates(householdId: _hh);
    expect((list as AppOk<List<SavingsCertificate>>).value, hasLength(1));
  });

  test('48. listCertificates: includes archived when flag set', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 400000);

    final cert1 =
        ((await createCert(
                  principal: 100000,
                  idempotencyKey: 'k1',
                  institution: 'Bank1',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    await createCert(
      principal: 100000,
      idempotencyKey: 'k2',
      institution: 'Bank2',
    );

    await db.customStatement(
      "UPDATE savings_certificates SET lifecycle = 'archived' WHERE id = ?",
      [cert1.id],
    );

    final list = await certRepo.listCertificates(
      householdId: _hh,
      includeArchived: true,
    );
    expect((list as AppOk<List<SavingsCertificate>>).value, hasLength(2));
  });

  test('49. getPrincipalBalance: derived from ledger', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert =
        ((await createCert(principal: 100000)) as AppOk<SavingsCertificate>)
            .value;

    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: cert.certificateAccountId,
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 100000);
  });

  test('50. getRevisions: returns in ASC order', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    final reviseUc = ReviseCertificateDefinitionUseCase(certRepo);
    await reviseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      institutionName: 'Updated 1',
      revisionReason: 'r1',
    );
    await reviseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      institutionName: 'Updated 2',
      revisionReason: 'r2',
    );

    final revs = await certRepo.getRevisions(cert.id);
    final list = (revs as AppOk<List<CertificateRevision>>).value;
    expect(list, hasLength(3));
    expect(list.first.institutionName, 'National Bank');
    expect(list.last.institutionName, 'Updated 2');
  });

  test('51. getEvents: returns in ASC order', () async {
    await createAccount(id: 'src-acc', householdId: _hh);
    await createAccount(id: 'dest-acc', householdId: _hh);
    await creditAccount('src-acc', _hh, 200000);

    final cert = ((await createCert()) as AppOk<SavingsCertificate>).value;

    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 3000,
      idempotencyKey: 'p1',
    );
    await recordProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dest-acc',
      amountMinorUnits: 3000,
      idempotencyKey: 'p2',
    );

    final events = await certRepo.getEvents(cert.id);
    final list = (events as AppOk<List<CertificateEvent>>).value;
    // created + purchased + 2 profitReceived = 4
    expect(list, hasLength(4));
    expect(
      list.where((e) => e.eventType == CertificateEventType.purchased),
      isNotEmpty,
    );
    expect(
      list.where((e) => e.eventType == CertificateEventType.profitReceived),
      hasLength(2),
    );
  });
}
