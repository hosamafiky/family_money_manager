# Localization Guide

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Language Strategy

| Language       | Code | Script | Direction | Status    |
| -------------- | ---- | ------ | --------- | --------- |
| Arabic (Egypt) | ar   | Arabic | RTL       | Primary   |
| English        | en   | Latin  | LTR       | Secondary |

Arabic is the primary language. The default locale is `ar_EG`. All strings must be translated into Arabic first, then English. No feature may launch with untranslated strings.

---

## 2. Tooling

- Flutter's built-in `flutter_localizations` + `intl` package.
- ARB (Application Resource Bundle) files: `lib/core/localization/l10n/app_ar.arb` and `app_en.arb`.
- Code generation: `flutter gen-l10n` produces `AppLocalizations`.
- Access in code: `context.l10n.someKey` or `ref.read(localizationProvider).someKey`.
- `intl` package handles pluralization, date formatting, number formatting, and currency formatting.

**Never:**

- Use hardcoded strings in widget code.
- Use translated text as database identifiers.
- Use English-only keys as user-visible text.

---

## 3. Key Naming Convention

Keys use `camelCase` with a feature prefix:

```
common_save
common_cancel
common_confirm
common_error_generic

auth_loginTitle
auth_emailHint
auth_passwordHint

dashboard_netWorth
dashboard_availableCash
dashboard_spouseWallet
dashboard_childFunds

account_personal_cash
account_spouse_wallet
account_home_savings
account_bank
account_certificate
account_gold
account_child_protected

transaction_income
transaction_expense
transaction_transfer

household_spouseSection
household_givenToSpouse
household_spouseSpent
household_spouseReturned
household_spouseBalance

child_protected_title
child_protected_withdrawWarning_ar    ← Arabic-specific key
child_protected_withdrawWarning_en    ← English-specific key
child_protected_reason_hint
child_protected_confirm

zakat_title
zakat_disclaimer_ar
zakat_disclaimer_en
zakat_nisab
zakat_zakatable
zakat_due

error_insufficientFunds
error_duplicateOperation
error_protectedFundWithdrawal
error_invalidTransfer
```

---

## 4. RTL Support

Flutter's `Directionality` widget is set automatically based on locale:

- Arabic locale → `TextDirection.rtl`
- English locale → `TextDirection.ltr`

Guidelines:

- Use `EdgeInsetsDirectional` instead of `EdgeInsets` for padding.
- Use `AlignmentDirectional` instead of `Alignment`.
- Use `Padding(padding: EdgeInsetsDirectional.only(start: 16))` — not `only(left: 16)`.
- Use `Row` with `MainAxisAlignment.start` — it respects directionality.
- Do not hard-code left/right icons for navigation; use `leading`/`trailing` widgets.
- Arrow icons: use `Icons.arrow_forward` and let Flutter mirror it for RTL.
- Charts: verify labels and axis direction are correct in both RTL and LTR.

---

## 5. Currency Formatting

Currency: Egyptian Pound (EGP)

| Amount             | Arabic display | English display |
| ------------------ | -------------- | --------------- |
| 100 minor units    | ١.٠٠ ج.م       | EGP 1.00        |
| 150000 minor units | ١٬٥٠٠.٠٠ ج.م   | EGP 1,500.00    |
| -50000 minor units | -٥٠٠.٠٠ ج.م    | -EGP 500.00     |

Formatter implementation:

```dart
class MoneyFormatter {
  static String format(Money money, Locale locale) {
    final amount = money.minorUnits / 100.0;
    if (locale.languageCode == 'ar') {
      // Use Arabic-Indic numerals and Arabic locale formatting
      final formatted = NumberFormat.currency(
        locale: 'ar_EG',
        symbol: 'ج.م',
        decimalDigits: 2,
      ).format(amount);
      return formatted;
    } else {
      return NumberFormat.currency(
        locale: 'en',
        symbol: 'EGP ',
        decimalDigits: 2,
      ).format(amount);
    }
  }

  // Redacted version for logging
  static String redacted() => '[REDACTED_AMOUNT]';
}
```

**Rules:**

- Always format with 2 decimal places.
- Use locale-appropriate thousands separator.
- Use locale-appropriate decimal separator.
- Arabic locale uses Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) by default in `intl`.
- Negative amounts display with a leading minus sign.
- Never display raw `minorUnits` to the user.

---

## 6. Date Formatting

| Context              | Arabic format | English format |
| -------------------- | ------------- | -------------- |
| Transaction date     | ١٥ يوليو ٢٠٢٦ | July 15, 2026  |
| Short date           | ١٥/٠٧/٢٠٢٦    | 07/15/2026     |
| Month + year         | يوليو ٢٠٢٦    | July 2026      |
| Relative (recent)    | منذ ٣ أيام    | 3 days ago     |
| Certificate maturity | ١ يناير ٢٠٢٧  | Jan 1, 2027    |

Date utilities:

```dart
class AppDateFormatter {
  static String formatLong(DateTime date, Locale locale) {
    return DateFormat.yMMMMd(locale.toString()).format(date);
  }

  static String formatShort(DateTime date, Locale locale) {
    return DateFormat.yMd(locale.toString()).format(date);
  }

  static String formatMonthYear(DateTime date, Locale locale) {
    return DateFormat.yMMMM(locale.toString()).format(date);
  }
}
```

Dates are stored internally as `String` in `YYYY-MM-DD` format (Gregorian). Display converts to locale-appropriate format.

---

## 7. Number Formatting

| Number type   | Arabic      | English      |
| ------------- | ----------- | ------------ |
| Integer count | ١٢٣         | 123          |
| Percentage    | ٨٠٪         | 80%          |
| Gold weight   | ١٠.٥٠٠ جرام | 10.500 g     |
| Interest rate | ٢٢٪ سنوياً  | 22% annually |

---

## 8. Arabic Financial Terminology

| English term       | Arabic term    |
| ------------------ | -------------- |
| Income             | دخل            |
| Expense            | مصروف          |
| Transfer           | تحويل          |
| Balance            | رصيد           |
| Available          | متاح           |
| Savings            | مدخرات         |
| Certificate        | شهادة          |
| Interest           | عائد           |
| Net worth          | صافي الثروة    |
| Assets             | أصول           |
| Liabilities        | التزامات       |
| Budget             | ميزانية        |
| Goal               | هدف            |
| Household          | الأسرة         |
| Personal           | شخصي           |
| Spouse             | الزوجة / الزوج |
| Child              | الطفل          |
| Protected          | محمي           |
| Gold               | ذهب            |
| Karat              | قيراط          |
| Gram               | جرام           |
| Bank account       | حساب بنكي      |
| Cash wallet        | محفظة نقدية    |
| Home savings       | مدخرات البيت   |
| Salary             | مرتب           |
| Transfer to spouse | تحويل للزوجة   |
| Return (money)     | إرجاع          |
| Spender            | المنفق         |
| Beneficiary        | المستفيد       |
| Zakat              | زكاة           |
| Nisab              | نصاب           |
| Hawl               | حول            |
| Sadaqah            | صدقة           |
| Opening balance    | رصيد أولي      |
| Adjustment         | تسوية          |
| Reversal           | إلغاء/عكس      |
| Maturity           | استحقاق        |
| Principal          | رأس المال      |
| Realized gain      | ربح محقق       |
| Unrealized gain    | ربح غير محقق   |
| Liability          | دَيْن / التزام |
| Repayment          | سداد           |

---

## 9. Protected Fund Warning — Arabic

```
⚠️ هذا المال محجوز ليوسف.

سيُسجَّل سحب هذا المبلغ بشكل دائم ولا يمكن حذفه.
يرجى ذكر سبب السحب قبل المتابعة.
```

The child's name is interpolated: replace "يوسف" with the household's configured child name.

ARB entry:

```json
"child_protected_withdrawWarning": "⚠️ هذا المال محجوز لـ{childName}.\n\nسيُسجَّل سحب هذا المبلغ بشكل دائم ولا يمكن حذفه.\nيرجى ذكر سبب السحب قبل المتابعة.",
"@child_protected_withdrawWarning": {
  "description": "Warning shown before withdrawing from child-protected fund",
  "placeholders": {
    "childName": {
      "type": "String",
      "example": "يوسف"
    }
  }
}
```

English equivalent:

```json
"child_protected_withdrawWarning": "⚠️ This money is reserved for {childName}.\n\nWithdrawing it will be permanently recorded and cannot be undone.\nPlease provide a reason before continuing.",
```

---

## 10. Zakat Disclaimer — Arabic

```
تنبيه: هذه الأداة للمساعدة في حساب الزكاة فقط، ولا تُغني عن استشارة عالم متخصص في فقه الزكاة لحالتك الخاصة.
```

ARB entry:

```json
"zakat_disclaimer": "تنبيه: هذه الأداة للمساعدة في حساب الزكاة فقط، ولا تُغني عن استشارة عالم متخصص في فقه الزكاة لحالتك الخاصة.",
"@zakat_disclaimer": {
  "description": "Legal/religious disclaimer for zakat calculation feature"
}
```

---

## 11. Pluralization

Arabic pluralization rules are complex (6 plural forms: zero, one, two, few, many, other).

Use `intl`'s `Intl.plural()` for all quantity strings.

Example:

```json
"transactionCount": "{count, plural, zero{لا توجد معاملات} one{معاملة واحدة} two{معاملتان} few{{count} معاملات} many{{count} معاملة} other{{count} معاملة}}",
```

Flutter's `gen-l10n` generates the correct pluralization logic from ARB files.

---

## 12. Screen Reader and Accessibility Labels

All interactive elements must have semantic labels in the current locale.

```dart
Semantics(
  label: context.l10n.account_balance_semantics(
    accountName: account.name,
    balance: MoneyFormatter.format(balance, locale),
  ),
  child: AccountBalanceCard(account: account, balance: balance),
)
```

Charts must include a text summary accessible to screen readers:

```dart
Semantics(
  label: context.l10n.netWorthChart_semantics(
    currentNetWorth: ...,
    change: ...,
    period: ...,
  ),
  excludeSemantics: true, // exclude child chart nodes
  child: NetWorthChart(...),
)
```

---

## 13. Privacy Mode

When privacy mode is enabled, all money amounts are replaced with `****` in the UI.

```dart
class MoneyDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPrivacyMode = ref.watch(privacyModeProvider);
    if (isPrivacyMode) return Text('****');
    return Text(MoneyFormatter.format(amount, locale));
  }
}
```

Privacy mode does not affect accessibility labels (screen readers still read the real amount).
If the user wants privacy from screen readers too, they should close the app.

---

## 14. Testing Localization

- Widget tests run in both `ar` and `en` locales.
- Golden tests (screenshot tests) capture both locales and both text directions.
- RTL layout verified: no text overflow, no icon mirroring issues, no incorrect padding.
- Pluralization tested: 0, 1, 2, 3, 11 items (Arabic has distinct plural forms for each).
- Currency formatting tested: positive, negative, zero, large numbers.
- Date formatting tested: Arabic-Indic numerals appear correctly in Arabic locale.
