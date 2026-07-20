import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:flutter_test/flutter_test.dart';

FinancialAccount _acct({
  required FinancialAccountType type,
  FundPurpose purpose = FundPurpose.available,
  bool archived = false,
  bool protected = false,
  bool spendable = true,
  String currency = 'EGP',
}) {
  return FinancialAccount(
    id: 'a1',
    householdId: 'h1',
    name: 'Test',
    type: type,
    ownerType: AccountOwnerType.user,
    fundPurpose: purpose,
    currencyCode: currency,
    isSpendable: spendable,
    isProtected: protected,
    includeInNetWorth: true,
    includeInZakat: false,
    isArchived: archived,
    displayOrder: 0,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    createdBy: 'u1',
  );
}

void main() {
  test('ordinary endpoints exclude reserve and certificate', () {
    expect(
      AccountEligibility.isOrdinaryTransactionEndpoint(
        _acct(type: FinancialAccountType.bankAccount),
      ),
      isTrue,
    );
    expect(
      AccountEligibility.isOrdinaryTransactionEndpoint(
        _acct(type: FinancialAccountType.goalReserve),
      ),
      isFalse,
    );
    expect(
      AccountEligibility.isOrdinaryTransactionEndpoint(
        _acct(type: FinancialAccountType.certificate),
      ),
      isFalse,
    );
    expect(
      AccountEligibility.isOrdinaryTransactionEndpoint(
        _acct(type: FinancialAccountType.bankAccount, archived: true),
      ),
      isFalse,
    );
  });

  test(
    'goal funding source excludes protected, reserve, certificate, non-spendable',
    () {
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(type: FinancialAccountType.bankAccount),
          currencyCode: 'EGP',
        ),
        isTrue,
      );
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(type: FinancialAccountType.bankAccount, protected: true),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(type: FinancialAccountType.goalReserve),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(type: FinancialAccountType.certificate, spendable: false),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(
            type: FinancialAccountType.bankAccount,
            purpose: FundPurpose.certificate,
          ),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalFundingSource(
          _acct(type: FinancialAccountType.bankAccount, spendable: false),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
    },
  );

  test(
    'goal release destination excludes reserve, certificate, non-spendable',
    () {
      expect(
        AccountEligibility.isGoalReleaseDestination(
          _acct(type: FinancialAccountType.bankAccount),
          currencyCode: 'EGP',
        ),
        isTrue,
      );
      expect(
        AccountEligibility.isGoalReleaseDestination(
          _acct(type: FinancialAccountType.certificate, spendable: false),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalReleaseDestination(
          _acct(type: FinancialAccountType.goalReserve, spendable: false),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
      expect(
        AccountEligibility.isGoalReleaseDestination(
          _acct(type: FinancialAccountType.bankAccount, spendable: false),
          currencyCode: 'EGP',
        ),
        isFalse,
      );
    },
  );

  test('ordinaryEndpointRejection maps reserved types', () {
    expect(
      AccountEligibility.ordinaryEndpointRejection(
        _acct(type: FinancialAccountType.goalReserve),
      ),
      AccountIneligibilityReason.goalReserve,
    );
    expect(
      AccountEligibility.ordinaryEndpointRejection(
        _acct(type: FinancialAccountType.certificate),
      ),
      AccountIneligibilityReason.certificate,
    );
  });

  test('goalFundingSourceRejection maps certificate', () {
    expect(
      AccountEligibility.goalFundingSourceRejection(
        _acct(type: FinancialAccountType.certificate, spendable: false),
        currencyCode: 'EGP',
      ),
      AccountIneligibilityReason.certificate,
    );
  });
}
