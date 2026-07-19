import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';

/// Returns the localized display label for a [TransactionCategory].
String categoryLabel(AppLocalizations l10n, TransactionCategory c) {
  return switch (c) {
    TransactionCategory.groceries => l10n.catGroceries,
    TransactionCategory.housing => l10n.catHousing,
    TransactionCategory.utilities => l10n.catUtilities,
    TransactionCategory.transportation => l10n.catTransportation,
    TransactionCategory.health => l10n.catHealth,
    TransactionCategory.education => l10n.catEducation,
    TransactionCategory.childExpenses => l10n.catChildExpenses,
    TransactionCategory.personalSpending => l10n.catPersonalSpending,
    TransactionCategory.spouseSpending => l10n.catSpouseSpending,
    TransactionCategory.giftsAndDonations => l10n.catGiftsAndDonations,
    TransactionCategory.otherExpense => l10n.catOtherExpense,
    TransactionCategory.salary => l10n.catSalary,
    TransactionCategory.businessIncome => l10n.catBusinessIncome,
    TransactionCategory.giftReceived => l10n.catGiftReceived,
    TransactionCategory.interestIncome => l10n.catInterestIncome,
    TransactionCategory.certificateProfit => l10n.catCertificateProfit,
    TransactionCategory.otherIncome => l10n.catOtherIncome,
  };
}
