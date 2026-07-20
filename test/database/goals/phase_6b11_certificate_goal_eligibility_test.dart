/// Phase 6B.1.1 – Direct SQL bypass tests for goal ↔ certificate eligibility.
///
/// These assert **DB-authoritative** rejection via
/// `validate_funding_source_eligibility` /
/// `validate_release_destination_eligibility`. They are distinct from UI
/// selector filters and use-case gates.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-6b11-sql';
const _hh2 = 'hh-6b11-sql-2';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftGoalRepository goalRepo;
  late DriftCertificateRepository certRepo;
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;
  late ReleaseGoalFundsUseCase releaseGoalUc;
  late CreateCertificateUseCase createCertUc;
  late RedeemCertificateUseCase redeemUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    goalRepo = DriftGoalRepository(db);
    certRepo = DriftCertificateRepository(db);
    createGoalUc = CreateGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    fundGoalUc = FundGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    releaseGoalUc = ReleaseGoalFundsUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    createCertUc = CreateCertificateUseCase(
      certRepository: certRepo,
      accountRepository: accountRepo,
    );
    redeemUc = RedeemCertificateUseCase(
      certRepository: certRepo,
      accountRepository: accountRepo,
    );
    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  Future<FinancialAccount> createAccount({
    required String id,
    required String householdId,
    String currency = 'EGP',
    String type = 'bankAccount',
    String fundPurpose = 'available',
    bool isSpendable = true,
    bool isProtected = false,
    AccountOwnerType ownerType = AccountOwnerType.user,
  }) {
    return accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: ownerType,
        fundPurpose: FundPurpose.fromCode(fundPurpose),
        currencyCode: currency,
        isSpendable: isSpendable,
        isProtected: isProtected,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
  }

  Future<void> creditAccount(String accId, String hhId, int amount) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'income-$accId-${DateTime.now().microsecondsSinceEpoch}',
        householdId: hhId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<SavingsGoal> createGoal({String key = 'ik-goal'}) async {
    final r = await createGoalUc.execute(
      goalName: 'Goal $key',
      purpose: GoalPurpose.travel,
      currencyCode: 'EGP',
      targetMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: key,
    );
    return (r as AppOk<SavingsGoal>).value;
  }

  Future<void> insertRawFundingAttempt({
    required String opId,
    required String movId,
    required String goalId,
    required String reserveId,
    required String sourceId,
    required String householdId,
    String currency = 'EGP',
  }) async {
    await db.customStatement(
      "INSERT INTO operations "
      "(id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id, idempotency_key) "
      "VALUES (?, ?, 'transfer', '2024-06-01', '2024-06-01T00:00:00Z', "
      "1000, ?, 'test', '2024-06-01', '2024-06-01', 'bypass', ?, ?, ?)",
      [opId, householdId, currency, sourceId, reserveId, 'ik-$opId'],
    );
    await db.customStatement(
      "INSERT INTO ledger_entries "
      "(id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "(?, ?, ?, ?, 'debit', 1000, ?, 'transferOut', '2024-06-01', "
      "'2024-06-01T00:00:00Z', 'test')",
      ['${opId}_d', opId, householdId, sourceId, currency],
    );
    await db.customStatement(
      "INSERT INTO ledger_entries "
      "(id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "(?, ?, ?, ?, 'credit', 1000, ?, 'transferIn', '2024-06-01', "
      "'2024-06-01T00:00:00Z', 'test')",
      ['${opId}_c', opId, householdId, reserveId, currency],
    );
    await db.customStatement(
      "INSERT INTO goal_movements "
      "(id, goal_id, household_id, transfer_operation_id, movement_type, created_at) "
      "VALUES (?, ?, ?, ?, 'funding', '2024-06-01T00:00:00Z')",
      [movId, goalId, householdId, opId],
    );
  }

  Future<void> insertRawReleaseAttempt({
    required String opId,
    required String movId,
    required String goalId,
    required String reserveId,
    required String destId,
    required String householdId,
  }) async {
    await db.customStatement(
      "INSERT INTO operations "
      "(id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id, idempotency_key) "
      "VALUES (?, ?, 'transfer', '2024-06-01', '2024-06-01T00:00:00Z', "
      "1000, 'EGP', 'test', '2024-06-01', '2024-06-01', 'bypass', ?, ?, ?)",
      [opId, householdId, reserveId, destId, 'ik-$opId'],
    );
    await db.customStatement(
      "INSERT INTO ledger_entries "
      "(id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "(?, ?, ?, ?, 'debit', 1000, 'EGP', 'transferOut', '2024-06-01', "
      "'2024-06-01T00:00:00Z', 'test')",
      ['${opId}_d', opId, householdId, reserveId],
    );
    await db.customStatement(
      "INSERT INTO ledger_entries "
      "(id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "(?, ?, ?, ?, 'credit', 1000, 'EGP', 'transferIn', '2024-06-01', "
      "'2024-06-01T00:00:00Z', 'test')",
      ['${opId}_c', opId, householdId, destId],
    );
    await db.customStatement(
      "INSERT INTO goal_movements "
      "(id, goal_id, household_id, transfer_operation_id, movement_type, "
      "created_at, release_reason) "
      "VALUES (?, ?, ?, ?, 'release', '2024-06-01T00:00:00Z', 'bypass')",
      [movId, goalId, householdId, opId],
    );
  }

  Future<void> expectAbort(
    Future<void> Function() action,
    String messageFragment,
  ) async {
    try {
      await action();
      fail('Expected SQLite abort containing "$messageFragment"');
    } catch (e) {
      expect(e.toString(), contains(messageFragment));
    }
  }

  // ── Reject cases ──────────────────────────────────────────────────────────

  test('SQL-1. Cert account funding a goal is rejected by trigger', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await creditAccount('bank', _hh, 200000);
    final cert = await createCertUc.execute(
      householdId: _hh,
      institutionName: 'NB',
      currencyCode: 'EGP',
      principalMinorUnits: 50000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'bank',
      idempotencyKey: 'ik-cert-1',
    );
    final certAcct =
        (cert as AppOk<SavingsCertificate>).value.certificateAccountId;
    final goal = await createGoal(key: 'ik-g1');

    await expectAbort(
      () => insertRawFundingAttempt(
        opId: 'op-bad-fund-cert',
        movId: 'mov-bad-fund-cert',
        goalId: goal.id,
        reserveId: goal.reserveAccountId,
        sourceId: certAcct,
        householdId: _hh,
      ),
      kGoalFundingSourceEligibilityAbort,
    );
  });

  test(
    'SQL-2. Goal release into cert account is rejected by trigger',
    () async {
      await createAccount(id: 'bank', householdId: _hh);
      await createAccount(id: 'dst', householdId: _hh);
      await creditAccount('bank', _hh, 200000);
      final goal = await createGoal(key: 'ik-g2');
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'bank',
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-g2',
      );
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-2',
      );
      final certAcct =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;

      await expectAbort(
        () => insertRawReleaseAttempt(
          opId: 'op-bad-rel-cert',
          movId: 'mov-bad-rel-cert',
          goalId: goal.id,
          reserveId: goal.reserveAccountId,
          destId: certAcct,
          householdId: _hh,
        ),
        kGoalReleaseDestinationEligibilityAbort,
      );
    },
  );

  test(
    'SQL-3. Account marked certificate by type rejected as funding source',
    () async {
      await createAccount(
        id: 'cert-type',
        householdId: _hh,
        type: 'certificate',
        fundPurpose: 'certificate',
        isSpendable: false,
        ownerType: AccountOwnerType.household,
      );
      // Seed balance without ordinary income (cert accounts blocked) via raw SQL.
      await db.customStatement(
        "INSERT INTO operations "
        "(id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('op-seed-ct', '$_hh', 'income', '2024-01-01', '2024-01-01', "
        "5000, 'EGP', 'test', '2024-01-01', '2024-01-01')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries "
        "(id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('le-seed-ct', 'op-seed-ct', '$_hh', 'cert-type', 'credit', 5000, "
        "'EGP', 'income', '2024-01-01', '2024-01-01', 'test')",
      );
      final goal = await createGoal(key: 'ik-g3');
      await expectAbort(
        () => insertRawFundingAttempt(
          opId: 'op-bad-type',
          movId: 'mov-bad-type',
          goalId: goal.id,
          reserveId: goal.reserveAccountId,
          sourceId: 'cert-type',
          householdId: _hh,
        ),
        kGoalFundingSourceEligibilityAbort,
      );
    },
  );

  test(
    'SQL-4. Account marked certificate by purpose rejected as funding source',
    () async {
      await createAccount(
        id: 'purpose-cert',
        householdId: _hh,
        type: 'bankAccount',
        fundPurpose: 'certificate',
        isSpendable: true,
      );
      await creditAccount('purpose-cert', _hh, 5000);
      final goal = await createGoal(key: 'ik-g4');
      await expectAbort(
        () => insertRawFundingAttempt(
          opId: 'op-bad-purpose',
          movId: 'mov-bad-purpose',
          goalId: goal.id,
          reserveId: goal.reserveAccountId,
          sourceId: 'purpose-cert',
          householdId: _hh,
        ),
        kGoalFundingSourceEligibilityAbort,
      );
    },
  );

  test(
    'SQL-5. Account linked to existing certificate rejected as funding source',
    () async {
      await createAccount(id: 'bank', householdId: _hh);
      await creditAccount('bank', _hh, 200000);
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-5',
      );
      final linked =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;
      final goal = await createGoal(key: 'ik-g5');
      await expectAbort(
        () => insertRawFundingAttempt(
          opId: 'op-bad-link',
          movId: 'mov-bad-link',
          goalId: goal.id,
          reserveId: goal.reserveAccountId,
          sourceId: linked,
          householdId: _hh,
        ),
        kGoalFundingSourceEligibilityAbort,
      );
    },
  );

  test('SQL-6. Non-spendable ordinary source rejected', () async {
    await createAccount(id: 'locked', householdId: _hh, isSpendable: false);
    await creditAccount('locked', _hh, 5000);
    final goal = await createGoal(key: 'ik-g6');
    await expectAbort(
      () => insertRawFundingAttempt(
        opId: 'op-bad-ns',
        movId: 'mov-bad-ns',
        goalId: goal.id,
        reserveId: goal.reserveAccountId,
        sourceId: 'locked',
        householdId: _hh,
      ),
      kGoalFundingSourceEligibilityAbort,
    );
  });

  test(
    'SQL-7. Non-spendable ordinary destination rejected on release',
    () async {
      await createAccount(id: 'bank', householdId: _hh);
      await createAccount(
        id: 'locked-dst',
        householdId: _hh,
        isSpendable: false,
      );
      await creditAccount('bank', _hh, 50000);
      final goal = await createGoal(key: 'ik-g7');
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'bank',
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-g7',
      );
      await expectAbort(
        () => insertRawReleaseAttempt(
          opId: 'op-bad-ns-dst',
          movId: 'mov-bad-ns-dst',
          goalId: goal.id,
          reserveId: goal.reserveAccountId,
          destId: 'locked-dst',
          householdId: _hh,
        ),
        kGoalReleaseDestinationEligibilityAbort,
      );
    },
  );

  test('SQL-8. Cross-household funding rejected', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await createAccount(id: 'bank2', householdId: _hh2);
    await creditAccount('bank2', _hh2, 5000);
    final goal = await createGoal(key: 'ik-g8');
    await expectAbort(
      () => insertRawFundingAttempt(
        opId: 'op-bad-xhh',
        movId: 'mov-bad-xhh',
        goalId: goal.id,
        reserveId: goal.reserveAccountId,
        sourceId: 'bank2',
        householdId: _hh,
      ),
      kGoalFundingSourceEligibilityAbort,
    );
  });

  test('SQL-9. Currency mismatch funding rejected', () async {
    await createAccount(id: 'usd', householdId: _hh, currency: 'USD');
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'income-usd',
        householdId: _hh,
        destinationAccountId: 'usd',
        amountMinorUnits: 5000,
        currencyCode: 'USD',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
    final goal = await createGoal(key: 'ik-g9');
    await expectAbort(
      () => insertRawFundingAttempt(
        opId: 'op-bad-ccy',
        movId: 'mov-bad-ccy',
        goalId: goal.id,
        reserveId: goal.reserveAccountId,
        sourceId: 'usd',
        householdId: _hh,
        currency: 'EGP',
      ),
      kGoalFundingSourceEligibilityAbort,
    );
  });

  // ── Positive controls ─────────────────────────────────────────────────────

  test('SQL-P1. Eligible standard can fund goal', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await creditAccount('bank', _hh, 50000);
    final goal = await createGoal(key: 'ik-gp1');
    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: 'bank',
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-p1',
    );
    expect(result, isA<AppOk<SavingsGoal>>());
  });

  test('SQL-P2. Goal release to eligible standard succeeds', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await createAccount(id: 'dst', householdId: _hh);
    await creditAccount('bank', _hh, 50000);
    final goal = await createGoal(key: 'ik-gp2');
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: 'bank',
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-p2',
    );
    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: 'dst',
      amountMinorUnits: 5000,
      releaseReason: 'need cash',
      householdId: _hh,
      idempotencyKey: 'ik-rel-p2',
    );
    expect(result, isA<AppOk<SavingsGoal>>());
  });

  test('SQL-P3. Cert purchase still credits cert account', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await creditAccount('bank', _hh, 200000);
    final result = await createCertUc.execute(
      householdId: _hh,
      institutionName: 'NB',
      currencyCode: 'EGP',
      principalMinorUnits: 75000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'bank',
      idempotencyKey: 'ik-cert-p3',
    );
    expect(result, isA<AppOk<SavingsCertificate>>());
    final cert = (result as AppOk<SavingsCertificate>).value;
    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: cert.certificateAccountId,
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 75000);
  });

  test('SQL-P4. Cert redemption still debits cert account', () async {
    await createAccount(id: 'bank', householdId: _hh);
    await createAccount(id: 'dst', householdId: _hh);
    await creditAccount('bank', _hh, 200000);
    final created = await createCertUc.execute(
      householdId: _hh,
      institutionName: 'NB',
      currencyCode: 'EGP',
      principalMinorUnits: 60000,
      startDate: '2024-01-01',
      maturityDate: '2024-06-01',
      sourceAccountId: 'bank',
      idempotencyKey: 'ik-cert-p4',
    );
    final cert = (created as AppOk<SavingsCertificate>).value;
    final redeemed = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      principalMinorUnits: 60000,
      idempotencyKey: 'ik-redeem-p4',
    );
    expect(redeemed, isA<AppOk<CertificateRedemptionSummary>>());
    final bal = await certRepo.getPrincipalBalance(
      certificateAccountId: cert.certificateAccountId,
      householdId: _hh,
    );
    expect((bal as AppOk<int>).value, 0);
  });
}
