# Test Strategy

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Philosophy

Tests are not optional. The financial domain requires correctness guarantees that only automated tests can provide at scale.

- Every financial invariant must have at least one test.
- Every error path must be tested.
- Financial domain logic must be 100% covered by unit tests.
- UI layer tests verify user-visible behavior, not implementation details.
- Tests must run quickly (full unit + widget suite < 90 seconds).
- Integration tests run in CI but are not required for local development cycles.

---

## 2. Test Pyramid

```
         ┌────────────┐
         │ Integration│  ~30 tests — slowest, most realistic
         │   Tests    │
        ┌┴────────────┴┐
        │ Widget Tests │  ~80 tests — test UI flows
        ┌┴──────────────┴┐
        │  Unit Tests    │  ~200+ tests — fastest, most numerous
        └────────────────┘
```

---

## 3. Unit Tests

Location: `test/unit/`

### 3.1 Financial Domain Tests

**`test/unit/core/financial/money_test.dart`**

- Money addition with matching currency
- Money subtraction
- Money equality
- Negative money representation
- Zero money
- Currency code enforcement (mismatched currency throws)
- Minor units never use double
- String formatting via MoneyFormatter (not Money itself)

**`test/unit/core/financial/ledger_calculator_test.dart`**

- Empty account balance = 0
- Single credit → balance = credit amount
- Single debit → balance = debit amount
- Mixed credits and debits → correct balance
- Balance as of a historical date (entries after date ignored)
- Zero balance after equal credits and debits
- Reversal entries cancel original entries
- Archived account balance still computable
- Backdated entry changes historical balance

**`test/unit/core/financial/net_worth_calculator_test.dart`**

- Net worth = sum of asset balances − sum of liabilities
- Transfer: net worth unchanged
- Income: net worth increases
- Expense: net worth decreases
- Certificate creation: net worth unchanged
- Certificate maturity: net worth unchanged (principal returned)
- Interest income: net worth increases
- Gold purchase: net worth unchanged (purchase price)
- Gold sale at gain: net worth increases by gain
- Gold sale at loss: net worth decreases by loss
- Liability creation: net worth decreases
- Liability principal repayment: net worth unchanged
- Liability interest payment: net worth decreases
- Archived account excluded from net worth
- Child fund: included or excluded per configuration

**`test/unit/features/transactions/income_test.dart`**

- Record salary income → destination account balance increases
- Record child gift → goes to childProtectedFund account
- Duplicate income operation (same operationId) → rejected
- Income with zero amount → rejected
- Income with negative amount → rejected
- Income scope validation

**`test/unit/features/transactions/expense_test.dart`**

- Record expense → source account balance decreases
- Expense with insufficient funds → InsufficientFundsError
- Expense from protected account without audit → rejected
- Expense scope: personal, household, spouse, child
- Spender and beneficiary recorded correctly
- Duplicate expense operation → rejected
- Expense does not count in transfer reports

**`test/unit/features/transfers/transfer_test.dart`**

- Transfer: source decreased, destination increased
- Transfer: same total balance before and after
- Transfer: source = destination → InvalidTransferError
- Transfer: zero amount → rejected
- Transfer: negative amount → rejected
- Transfer: insufficient funds → InsufficientFundsError
- Transfer fee: recorded as separate expense, reduces net worth
- Transfer fee: does NOT affect source and destination balance sum
- Duplicate transfer (same operationId) → rejected
- Transfer not in income or expense report
- Transfer reversal: original transfer nullified, balances restored
- Atomic: if second entry fails, first entry also rolled back

**`test/unit/features/household/spouse_wallet_test.dart`**

- Transfer to spouse wallet → balance increases
- Record spouse expense → wallet balance decreases
- Return money from spouse wallet → balance decreases
- Spouse wallet balance formula: transfers_in − expenses − transfers_out
- Spouse wallet balance never negative (unless overdraft allowed)
- Spouse spending report: shows given, spent, returned, remaining

**`test/unit/features/household/child_fund_test.dart`**

- Child fund deposit → balance increases
- Child fund withdrawal WITH audit → succeeds
- Child fund withdrawal WITHOUT audit → rejected
- Child fund withdrawal: audit is immutable
- Child fund withdrawal: reason required and non-empty
- Child fund withdrawal: warning flag must be true
- Withdrawal reason preserved in history
- Multiple deposits and withdrawals: balance formula correct
- Child fund not counted in available spendable money

**`test/unit/features/certificates/certificate_test.dart`**

- Create certificate: bank account balance decreases by principal
- Create certificate: certificate account balance = principal
- Create certificate: sum of bank + certificate = bank balance before creation
- Record interest payout: certificate balance unchanged
- Record interest payout: destination account balance increases
- Record interest payout: net worth increases
- Mature certificate: principal returns to destination account
- Mature certificate: certificate balance = 0
- Mature certificate: final interest recorded separately
- Early redemption: principal returned, certificate marked redeemed_early
- Duplicate certificate creation operation → rejected

**`test/unit/features/gold/gold_test.dart`**

- Buy gold: source account decreases by purchase price + fee
- Buy gold: gold account balance = purchase price
- Buy gold: net worth unchanged (excluding fee)
- Making charge: recorded as expense
- Update gold price: unrealized gain/loss recalculated
- Sell all gold: gold position reduces to zero
- Sell partial gold: remaining weight = original − sold
- Gold sale at gain: realized gain = sale proceeds − purchase value of sold portion
- Gold sale at loss: realized loss
- Gold weight stored as integer milligrams
- 10.5g stored as 10500 milligrams

**`test/unit/features/liabilities/liability_test.dart`**

- Create liability: outstanding = original amount
- Repay principal: outstanding decreases, payment account decreases
- Repay principal: net worth unchanged
- Repay interest: payment account decreases, net worth decreases
- Repay principal + interest: both recorded separately
- Settle liability: outstanding = 0, isSettled = true
- Active liability reduces net worth
- Settled liability not in net worth calculation

**`test/unit/features/budgets/budget_test.dart`**

- Budget spending = sum of expenses in period matching scope/category
- Transfers NOT counted in budget spending
- Certificate funding NOT counted in budget
- Gold purchase NOT counted in ordinary budget
- Transfer fee IS counted in budget
- Warning at threshold: budget 80% used → warning triggered
- Over budget: overspending notification
- Personal vs. household budget separate

**`test/unit/features/zakat/zakat_test.dart`**

- Zakatable amount = sum of included accounts
- Deducted liabilities reduce zakatable amount
- Zakat due = 2.5% of (zakatable − deducted) if above nisab
- Below nisab: zakat due = 0
- Gold karat factor applied correctly
- Excluded accounts not counted
- Child fund: excluded by default, optional to include

**`test/unit/core/financial/idempotency_test.dart`**

- Same operationId submitted twice: second is rejected with DuplicateOperationError
- Balance unchanged after duplicate submission

**`test/unit/core/financial/historical_balance_test.dart`**

- Balance as of date: entries after date excluded
- Backdated entry: included in historical balance for that date
- Running balance at multiple dates: correct sequence

---

### 3.2 Data Layer Tests

**`test/unit/data/serialization_test.dart`**

- LedgerEntry → JSON → LedgerEntry: round-trip identity
- Operation → JSON → Operation: round-trip identity
- FinancialAccount → JSON → FinancialAccount: round-trip identity
- Unknown enum value in JSON: stored as-is, not rejected
- Unknown field in JSON: ignored (forward compatibility)
- Missing optional field: defaults applied correctly

**`test/unit/data/migration_test.dart`**

- Schema v1: all tables created correctly
- Migration from v1 to v2 (when v2 is defined): incremental
- After migration: data integrity preserved

**`test/unit/data/backup_test.dart`**

- Backup file created with correct manifest
- Backup file encrypted: raw SQLite not readable without key
- Import valid backup: all records restored
- Import backup with wrong schema version: rejected
- Import backup with invalid enum: rejected
- Import backup with negative amount: rejected
- Import backup: preview shows correct counts before commit
- Import with replace: auto-backup created first
- Import cancelled: original data unchanged

---

## 4. Widget Tests

Location: `test/widget/`

### 4.1 Core UI Tests

**`test/widget/auth/login_screen_test.dart`**

- Login screen renders in Arabic RTL
- Login screen renders in English LTR
- Empty email → validation error shown
- Invalid email → validation error shown
- Wrong password → error message displayed
- Successful login → navigates to dashboard

**`test/widget/onboarding/onboarding_test.dart`**

- Language selection step shown first
- Arabic selected → app switches to RTL
- Household name input validated
- Member names input
- Account creation step: add personal cash, bank account
- Opening balance entry
- Completing onboarding → dashboard shown

**`test/widget/dashboard/dashboard_test.dart`**

- Dashboard shows all account balances
- Net worth card shows correct total
- Spouse wallet card shows balance
- Child fund card shows balance
- Privacy mode: amounts replaced with \*\*\*\*
- Recent transactions visible

**`test/widget/transactions/add_income_test.dart`**

- Add income form renders
- Amount, category, destination account fields
- Submit with valid data → income recorded
- Submit with zero amount → validation error
- Cancel → no operation recorded

**`test/widget/transactions/add_expense_test.dart`**

- Add expense form renders
- Spender and beneficiary fields
- Scope selection (personal/household/spouse/child)
- Receipt attachment (optional)
- Submit → expense recorded
- Insufficient funds → error message

**`test/widget/transfers/transfer_test.dart`**

- Transfer form renders
- Source and destination selectors
- Source = destination → disabled confirmation
- Amount entry
- Transfer fee (optional)
- Confirm → transfer recorded

**`test/widget/household/spouse_wallet_test.dart`**

- Spouse wallet section shows given, spent, remaining
- "Give money to spouse" action
- Record spouse expense
- Return spouse money
- Running balance matches formula

**`test/widget/household/child_fund_test.dart`**

- Child fund screen shows balance, deposits, withdrawals
- Add deposit
- Withdraw: warning dialog shown
- Withdraw: warning dialog in Arabic
- Withdraw: reason input required
- Withdraw: confirm → audit recorded
- Withdraw: cancel → no operation
- Audit history visible

**`test/widget/certificates/certificate_test.dart`**

- Create certificate form
- Source bank account balance shown
- Principal > available balance → disabled
- Create → certificate created, bank balance updated
- Certificate list shows all active certificates
- Record interest payout
- Mature certificate flow

**`test/widget/gold/gold_test.dart`**

- Buy gold form
- Weight in grams (displayed), stored as milligrams
- Source account balance shown
- Buy → gold position created
- Update price
- Sell gold form
- Realized gain/loss shown

**`test/widget/zakat/zakat_test.dart`**

- Zakat calculator screen
- Disclaimer shown prominently
- Asset selection toggles
- Liability deduction
- Calculation result shown
- Nisab comparison shown
- Payment recording

**`test/widget/security/app_lock_test.dart`**

- App lock screen shown when locked
- Correct PIN → unlocks
- Wrong PIN → error + incrementing delay
- Biometric prompt shown
- Lock on background
- Privacy mode toggle

**`test/widget/backup/backup_restore_test.dart`**

- Backup creation
- Backup list
- Restore: preview shown
- Restore: confirmation required
- Restore: PIN re-authentication

**`test/widget/localization/rtl_test.dart`**

- All key screens render correctly in Arabic RTL
- No text overflow in Arabic
- Navigation arrows mirrored in RTL
- Forms layout correct in RTL

**`test/widget/localization/ltr_test.dart`**

- All key screens render correctly in English LTR

**`test/widget/accessibility/semantics_test.dart`**

- Account balance cards have correct semantic labels
- Buttons have correct accessible names
- Charts have text summaries for screen readers
- Large touch targets (minimum 48x48 dp)

---

## 5. Integration Tests

Location: `test/integration/`

These run on a real device or emulator using `flutter test integration_test/`.

**`test/integration/household_setup_test.dart`**

- Fresh install → onboarding
- Create all accounts with opening balances
- Verify all balances on dashboard
- Verify net worth calculation

**`test/integration/spouse_wallet_flow_test.dart`**

- Transfer home savings to wife wallet
- Record spouse grocery expense
- Record spouse healthcare expense
- Return unused money
- Verify wallet balance = 0
- Verify home savings balance = original − net spent

**`test/integration/child_fund_flow_test.dart`**

- Deposit child gift money
- View balance
- Withdraw with reason
- View audit history
- Attempt second withdrawal: warning shown again

**`test/integration/certificate_flow_test.dart`**

- Create bank account with opening balance
- Create certificate from bank account
- Verify bank balance reduced
- Record monthly interest
- Mature certificate
- Verify principal returned to bank

**`test/integration/gold_flow_test.dart`**

- Buy gold from home savings
- Update gold price
- View unrealized gain
- Sell partial gold
- View realized gain

**`test/integration/offline_sync_test.dart`**

- Disable connectivity
- Record expense offline
- Record transfer offline
- Verify local balances correct
- Restore connectivity
- Verify sync queue processed
- Verify Firestore contains correct records

**`test/integration/conflict_test.dart`**

- (Simulated) Two operations submitted with same operation ID
- Verify only first is applied
- Verify conflict surfaced if amounts differ

**`test/integration/sign_out_isolation_test.dart`**

- User A creates accounts and transactions
- User A signs out
- User B signs in
- Verify User B sees empty state (no User A data)

**`test/integration/backup_restore_test.dart`**

- Create household with all account types and transactions
- Create backup
- Delete all data (simulate factory reset)
- Restore from backup
- Verify all accounts, balances, and audit history restored

---

## 6. Firestore Rules Tests

Location: `firestore_rules/firestore.test.js`

Run with: `firebase emulators:start && npm test`

Required tests:

- Owner can read/write own household
- Non-owner cannot read/write
- Unauthenticated cannot read/write
- Ledger entry: create succeeds with valid data
- Ledger entry: update rejected
- Ledger entry: delete rejected
- Ledger entry: negative amount rejected
- Ledger entry: duplicate ID rejected
- Child audit: create with warningShown = false rejected
- Child audit: create with empty reason rejected
- Child audit: update rejected
- Cross-user: User A cannot read User B's data
- Cross-user: User A cannot write to User B's household

---

## 7. Security Tests

**`test/unit/security/log_redaction_test.dart`**

- Logger with Money value: output contains [REDACTED_AMOUNT]
- Logger with auth token: output contains [REDACTED_TOKEN]
- Logger with account balance: redacted
- Normal log messages: pass through unchanged

**`test/unit/security/pin_test.dart`**

- PIN hash is not the raw PIN
- Two identical PINs with different salts produce different hashes
- PIN verification: correct PIN returns true
- PIN verification: wrong PIN returns false
- Exponential backoff state persists after app restart

**`test/unit/security/backup_validation_test.dart`**

- Schema version > current: rejected
- Invalid enum codes: rejected
- Negative amounts: rejected
- Invalid UUID format: rejected
- Wrong household ID: rejected
- Valid backup: accepted

---

## 8. Performance Tests

Not automated in v1. Manual performance checkpoints:

- Dashboard load: < 500ms on mid-range Android (balance queries)
- Transaction list (500+ items): smooth scrolling, < 100ms to load
- Adding a transaction: < 200ms to local commit
- Sync queue processing: < 2 seconds for 50 pending items
- Net worth calculation: < 100ms for 5 years of data

---

## 9. Test Utilities

**`test/helpers/test_database.dart`**

```dart
Future<AppDatabase> createTestDatabase() async {
  return AppDatabase(NativeDatabase.memory());
}
```

**`test/helpers/test_factories.dart`**

- `makeHousehold({...overrides})`
- `makeAccount({...overrides})`
- `makeLedgerEntry({...overrides})`
- `makeIncomeOperation({...overrides})`
- `makeExpenseOperation({...overrides})`
- `makeTransferOperation({...overrides})`
- `makeChildFundWithdrawalAudit({...overrides})`
- `makeMoney({int minorUnits = 10000, String currency = 'EGP'})`

**`test/helpers/fake_repositories.dart`**

- `FakeAccountRepository`
- `FakeLedgerRepository`
- `FakeOperationRepository`
- `FakeSyncService` (no-op sync)

---

## 10. CI Configuration

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-warnings
      - run: flutter test --coverage
      - name: Check coverage
        run: |
          # Fail if domain/application coverage < 80%
          genhtml coverage/lcov.info -o coverage/html

  firestore-rules:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm install -g firebase-tools
      - run: firebase emulators:exec --only firestore 'npm test' --project demo-test
```

---

## 11. Test Coverage Targets

| Layer                      | Target               |
| -------------------------- | -------------------- |
| `core/financial/`          | 100%                 |
| `features/*/domain/`       | 100%                 |
| `features/*/application/`  | ≥ 85%                |
| `features/*/data/`         | ≥ 80%                |
| `features/*/presentation/` | ≥ 60% (widget tests) |
| Overall                    | ≥ 75%                |
