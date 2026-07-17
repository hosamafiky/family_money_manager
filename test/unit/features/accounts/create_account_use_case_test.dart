import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/application/create_account_use_case.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_ledger_repository.dart';

void main() {
  late FakeAccountRepository accountRepo;
  late FakeLedgerRepository ledgerRepo;
  late AppDatabase db;

  setUp(() {
    accountRepo = FakeAccountRepository();
    ledgerRepo = FakeLedgerRepository();
    db = AppDatabase.forTesting();
  });

  tearDown(() async => db.close());

  CreateAccountWorkflowParams baseParams({String name = 'My Wallet', int? openingBalance}) =>
      CreateAccountWorkflowParams(
        householdId: 'hh1',
        name: name,
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: true,
        createdBy: 'user1',
        openingBalanceMinorUnits: openingBalance,
      );

  CreateAccountUseCase buildUseCase() =>
      CreateAccountUseCase(accountRepository: accountRepo, ledgerRepository: ledgerRepo, db: db);

  group('CreateAccountUseCase validation', () {
    test('empty name returns AppValidationFailure', () async {
      final result = await buildUseCase().execute(baseParams(name: ''));
      expect(result, isA<AppValidationFailure<FinancialAccount>>());
      final failure = result as AppValidationFailure<FinancialAccount>;
      expect(failure.field, 'name');
      expect(failure.messageKey, 'error_account_name_empty');
    });

    test('blank name (whitespace only) returns AppValidationFailure', () async {
      final result = await buildUseCase().execute(baseParams(name: '   '));
      expect(result, isA<AppValidationFailure<FinancialAccount>>());
      final failure = result as AppValidationFailure<FinancialAccount>;
      expect(failure.field, 'name');
    });

    test('negative opening balance returns AppValidationFailure', () async {
      final result = await buildUseCase().execute(baseParams(openingBalance: -100));
      expect(result, isA<AppValidationFailure<FinancialAccount>>());
      final failure = result as AppValidationFailure<FinancialAccount>;
      expect(failure.field, 'openingBalance');
      expect(failure.messageKey, 'error_opening_balance_negative');
    });

    test('zero opening balance is allowed (no ledger entry created)', () async {
      final result = await buildUseCase().execute(baseParams(openingBalance: 0));
      expect(result, isA<AppOk<FinancialAccount>>());
      expect(ledgerRepo.recordedOpeningBalances, isEmpty);
    });

    test('valid params returns AppOk', () async {
      final result = await buildUseCase().execute(baseParams());
      expect(result, isA<AppOk<FinancialAccount>>());
    });

    test('name is trimmed before creation', () async {
      final result = await buildUseCase().execute(baseParams(name: '  My Wallet  '));
      expect(result, isA<AppOk<FinancialAccount>>());
      final account = (result as AppOk<FinancialAccount>).value;
      expect(account.name, 'My Wallet');
    });

    test('positive opening balance records opening balance entry', () async {
      final result = await buildUseCase().execute(baseParams(openingBalance: 500));
      expect(result, isA<AppOk<FinancialAccount>>());
      expect(ledgerRepo.recordedOpeningBalances, hasLength(1));
      expect(ledgerRepo.recordedOpeningBalances.first.amountMinorUnits, 500);
    });
  });
}
