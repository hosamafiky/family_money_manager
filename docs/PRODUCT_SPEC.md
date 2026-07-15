# Family Money Manager — Product Specification

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15  
**Status:** Draft — Phase 0 Planning

---

## 1. Purpose

Family Money Manager is a private, household-grade financial management application designed for a married user with dependents. It is not a generic expense tracker. It is a trustworthy household financial ledger where every amount of money has exactly one location, one owner, one purpose, and a complete auditable movement history at all times.

The application operates on an immutable, append-only double-entry ledger. Every financial event is permanently recorded. Nothing is silently overwritten. The application can reconstruct the state of any account at any point in time from the ledger alone.

---

## 2. Audience

Primary user: A married adult who manages household finances for themselves, a spouse, and one or more children. The primary user is technically comfortable with smartphones but is not a financial professional.

Secondary consideration: The spouse does not require a separate login in v1. The primary user manages all records on behalf of the household.

See `USER_PERSONAS.md` for full persona profiles.

---

## 3. Core Value Proposition

| Problem | Solution |
|---|---|
| "I don't know how much cash I actually have across all my accounts." | Dashboard shows every account balance derived from the ledger. |
| "I gave my wife money for groceries and can't track what she spent and what's left." | Spouse wallet model with transfer, spending, and return tracking. |
| "I'm not sure if money I put in a certificate is still counted in my bank balance." | Certificate funding removes principal from source account atomically. |
| "I want to track my child's gift money separately and protect it." | Child-protected funds with mandatory withdrawal audit and warnings. |
| "I have gold and savings at home but no way to include them in my net worth." | Gold holdings and home savings accounts with ledger-backed balances. |
| "I don't know my real net worth." | True net worth = Total assets − Total liabilities, live and historical. |

---

## 4. Application Name and Branding

| Property | Default Value |
|---|---|
| Application name (display) | Family Money Manager |
| Application name (Arabic) | مدير مالية الأسرة |
| Package name (Android) | com.familymoney.manager |
| Bundle ID (iOS) | com.familymoney.manager |
| Primary currency | EGP (Egyptian Pound) |
| Default locale | Arabic (Egypt) — ar_EG |
| Fallback locale | English — en |

All branding, color scheme, package name, and app name values must be configurable via a central configuration file before any build.

---

## 5. Supported Platforms

| Platform | Target |
|---|---|
| Android | API 26+ (Android 8.0) |
| iOS | iOS 15+ |
| Web | Not in scope for v1 |
| Desktop | Not in scope for v1 |

---

## 6. Feature Inventory

### 6.1 Financial Accounts

- Create multiple accounts of each type
- Account types: personalCashWallet, spouseCashWallet, householdCash, homeSavingsCash, bankAccount, mobileWallet, childProtectedFund, goalReserve, certificate, goldHolding, investment, otherAsset
- Account owner: user, spouse, household, child, shared
- Fund purpose: available, householdSpending, personalSpending, emergencySavings, longTermSavings, childProtected, investment, certificate, gold, custom
- Balance derived from ledger (never stored directly)
- Spendable flag, protected flag, net-worth inclusion flag, zakat inclusion flag
- Archived state (soft delete with full history)
- Notes and audit metadata

### 6.2 Income

- Record income to any account
- Categories: Salary, Business, Gift, CertificateInterest, InvestmentReturn, Refund, ChildGift, Other
- Custom categories
- Source label (employer, payer, etc.)
- Scope: personal, household, child
- Recurring income support
- Child gift defaults to child-protected account

### 6.3 Expenses

- Record expense from any account
- Category (customizable, default list provided)
- Spender (user, spouse, child, other)
- Beneficiary (may differ from spender)
- Scope: personal, household, spouse, child, shared
- Notes and optional receipt
- Recurring expense support
- Expense does not affect net worth positively

### 6.4 Transfers

- Transfer between any two different accounts
- Transfer is atomic: source debited and destination credited in one operation
- Optional transfer fee (recorded as expense)
- Transfer does not count as income or expense
- Transfer does not affect net worth (except fee)
- Reversal is append-only

### 6.5 Spouse Wallet

- Dedicated spouse cash wallet account
- User transfers money to spouse wallet
- Record spouse expenses (paid by spouse from her wallet)
- Record household expenses paid by user on behalf of household
- Return unused spouse-wallet money to any account
- Dashboard shows: given, spent, returned, remaining balance

### 6.6 Child-Protected Funds

- One or more dedicated child-protected accounts
- Not counted as household spending money
- Withdrawal requires: warning display, reason, beneficiary, confirmation, audit entry
- Optional biometric or PIN gate before withdrawal
- History: deposits, withdrawals, reasons, operators
- Arabic warning localization required

### 6.7 Home Savings

- Separate named savings accounts (cash, emergency, family, long-term)
- Ledger-backed, not editable directly
- Transfer to/from any other account
- Protected or available flags
- Notes and purpose

### 6.8 Bank Accounts

- Multiple bank accounts
- Fields: bank name, nickname, last-four, notes, interest, archived
- Linked certificates list
- Income, expense, and transfer transactions
- Reconciliation: auditable adjustment when app balance ≠ real balance

### 6.9 Certificates

- Linked to a bank account
- Fields: principal, start date, maturity date, rate type, rate, payout frequency, payout destination
- Creation: transfers principal out of source bank account (atomic)
- Interest payout: recorded as income to destination account
- Maturity: returns principal + final interest, marks certificate as matured
- Status: active, matured, redeemed_early, cancelled

### 6.10 Gold Holdings

- Type, karat, weight (grams), purchase price, current price, purchase date
- Funding account (source of purchase)
- Purchase: reduces source account, creates gold holding position
- Sale: reduces gold position, deposits proceeds to selected account, records realized gain/loss
- Manual price update
- Unrealized gain/loss display

### 6.11 Goals

- Target amount, current funded amount, deadline
- Linked goal reserve account
- Funding is a transfer to goal reserve
- Withdrawal is a transfer from goal reserve
- Completion, cancellation with destination account
- Contribution history

### 6.12 Liabilities and Debts

- Types: personal loan, credit card, borrowed from person, owed to supplier, installment, lent to person
- Fields: name, original amount, outstanding, due date, payment account, interest, notes, active/settled
- Repayment: separates principal, interest, fees
- Net worth: assets − liabilities

### 6.13 Budgets

- Household, personal, spouse, child budgets
- Category budgets
- Monthly and custom period budgets
- Warning thresholds and overspending alerts
- Transfers excluded from budget spending

### 6.14 Dashboard

- Arabic-first design
- Available spendable money (aggregate)
- Per-account balance cards
- Child-protected funds total
- Net worth summary
- Month-to-date: personal spending, household spending, child spending
- Spouse wallet summary
- Upcoming bills / recurring items
- Budget warnings
- Recent transactions
- Privacy mode (blur all amounts)

### 6.15 Reports and Analytics

- Spending by category, owner, scope, account, date
- Cash-flow trends
- Asset trends
- Liability trends
- Net-worth trends
- All transfers excluded from income/expense reports
- Filters: date, account, owner, spender, beneficiary, scope, category

### 6.16 Zakat and Sadaqah

- Configurable per-asset inclusion
- Nisab, hawl, calculation date
- Deducted liabilities
- Calculation history
- Disclaimer: assistance tool, not religious ruling
- Sadaqah logging with expense link
- No double-counting of linked transactions

### 6.17 Voice and Optional AI

- Arabic voice input for transaction entry
- AI proposes operations (transfer + expense, etc.)
- User reviews and confirms before saving
- AI is optional; app fully functional without it
- AI never writes directly to the database
- API secrets never embedded in mobile app

### 6.18 Security and Lock

- PIN app lock
- Biometric unlock (fingerprint, Face ID)
- PIN fallback
- Auto-lock timeout (configurable)
- Lock on background
- Privacy mode (hidden amounts)
- Obscured app switcher
- Optional screenshot protection
- Re-authentication for destructive operations

### 6.19 Offline-First Sync

- Local SQLite (Drift) as primary database
- Full offline operation
- Optional Firebase Auth + Firestore cloud sync
- Sync queue for pending operations
- Idempotent operations
- Explicit conflict resolution
- Sync status visible

### 6.20 Backup and Restore

- Versioned encrypted backups
- Export/import preview
- Merge or replace mode
- Auto-backup before replace
- Schema validation on import

### 6.21 Localization

- Arabic (primary, RTL)
- English (secondary, LTR)
- Correct EGP currency formatting
- Correct Arabic number/date formatting
- Arabic pluralization rules

---

## 7. Out of Scope for v1

- Multi-user household login (spouse app access)
- Live market data (gold price API)
- Stock or equity investment tracking beyond simple records
- Web or desktop platform
- AI that writes directly to the database
- Multi-currency within a single household
- Automatic bank statement import (OFX/QIF/CSV)
- Push notifications from cloud (local notifications only)

---

## 8. Success Criteria

The application is considered correctly built when:

1. Every EGP amount has exactly one location at all times.
2. Transfers never create or destroy money.
3. Net worth is always equal to total assets minus total liabilities.
4. Every withdrawal from a child-protected account has a permanently recorded reason.
5. Certificate principal is not counted in both the bank account and the certificate simultaneously.
6. Spouse-wallet balance is always: (sum of transfers in) − (sum of expenses paid) − (sum of transfers out).
7. All ledger operations are idempotent — applying the same operation twice has no additional effect.
8. The application works fully offline with no degradation of financial operation quality.
9. All amounts are stored as integer minor units. No double is used for persisted money.
10. All text in the Arabic locale is grammatically correct financial Arabic.
