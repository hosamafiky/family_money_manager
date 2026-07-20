/// Phase 6B.1.1 – Application-layer typed rejections for certificate endpoints.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/data/goal_transfer_write_boundary.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

const _hh = 'hh-6b11-app';

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
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<void> createBank(String id) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: id,
        type: FinancialAccountType.bankAccount,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-$id',
        householdId: _hh,
        destinationAccountId: id,
        amountMinorUnits: 200000,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<SavingsGoal> makeGoal(String key) async {
    final r = await createGoalUc.execute(
      goalName: 'G',
      purpose: GoalPurpose.travel,
      currencyCode: 'EGP',
      targetMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: key,
    );
    return (r as AppOk<SavingsGoal>).value;
  }

  test(
    'UC-1. FundGoalUseCase typed rejection for certificate source',
    () async {
      await createBank('bank');
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 50000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-uc1',
      );
      final certAcct =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;
      final goal = await makeGoal('ik-g-uc1');

      final result = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: certAcct,
        amountMinorUnits: 1000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-uc1',
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure<SavingsGoal>).messageKey,
        'errorCertificateAccountNotAllowedAsSource',
      );
    },
  );

  test(
    'UC-2. ReleaseGoalFundsUseCase typed rejection for certificate destination',
    () async {
      await createBank('bank');
      await createBank('dst');
      final goal = await makeGoal('ik-g-uc2');
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'bank',
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-uc2',
      );
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-uc2',
      );
      final certAcct =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;

      final result = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: certAcct,
        amountMinorUnits: 1000,
        releaseReason: 'test',
        householdId: _hh,
        idempotencyKey: 'ik-rel-uc2',
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure<SavingsGoal>).messageKey,
        'errorCertificateAccountNotAllowedAsDestination',
      );
    },
  );

  test(
    'UC-3. Direct repository fundGoalTransfer cannot bypass certificate source gate',
    () async {
      await createBank('bank');
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 50000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-uc3',
      );
      final certAcct =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;
      final goal = await makeGoal('ik-g-uc3');
      final now = DateTime.now().toUtc().toIso8601String();

      final result = await goalRepo.fundGoalTransfer(
        GoalAssociatedTransferParams.funding(
          goalId: goal.id,
          householdId: _hh,
          operationId: const Uuid().v4(),
          idempotencyKey: 'ik-repo-fund-uc3',
          sourceAccountId: certAcct,
          destinationAccountId: goal.reserveAccountId,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'test',
          description: 'bypass attempt',
          movementId: const Uuid().v4(),
          movementCreatedAt: now,
        ),
      );
      expect(result, isA<AppValidationFailure<GoalTransferWriteResult>>());
      expect(
        (result as AppValidationFailure<GoalTransferWriteResult>).messageKey,
        'errorCertificateAccountNotAllowedAsSource',
      );
    },
  );

  test(
    'UC-4. Direct repository releaseGoalTransfer cannot bypass certificate dest gate',
    () async {
      await createBank('bank');
      final goal = await makeGoal('ik-g-uc4');
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'bank',
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-uc4',
      );
      final cert = await createCertUc.execute(
        householdId: _hh,
        institutionName: 'NB',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'bank',
        idempotencyKey: 'ik-cert-uc4',
      );
      final certAcct =
          (cert as AppOk<SavingsCertificate>).value.certificateAccountId;
      final now = DateTime.now().toUtc().toIso8601String();

      final result = await goalRepo.releaseGoalTransfer(
        GoalAssociatedTransferParams.release(
          goalId: goal.id,
          householdId: _hh,
          operationId: const Uuid().v4(),
          idempotencyKey: 'ik-repo-rel-uc4',
          sourceAccountId: goal.reserveAccountId,
          destinationAccountId: certAcct,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'test',
          description: 'bypass attempt',
          movementId: const Uuid().v4(),
          movementCreatedAt: now,
          releaseReason: 'bypass',
        ),
      );
      expect(result, isA<AppValidationFailure<GoalTransferWriteResult>>());
      expect(
        (result as AppValidationFailure<GoalTransferWriteResult>).messageKey,
        'errorCertificateAccountNotAllowedAsDestination',
      );
    },
  );
}
