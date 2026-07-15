# User Journeys

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## Journey 1 — First Household Setup

**Actor:** Ahmad (first launch)  
**Goal:** Set up all his financial accounts and initial balances in one session

### Steps

1. Ahmad opens the app for the first time.
2. Onboarding: language selection (Arabic/English), currency (EGP default).
3. Onboarding: Set up household name and members (himself, spouse name, child name).
4. Onboarding: Add accounts — guided wizard suggests common account types.
5. Ahmad creates:
   - My Personal Cash (personalCashWallet, owner: user)
   - Wife Wallet (spouseCashWallet, owner: spouse)
   - Home Savings (homeSavingsCash, owner: household)
   - Bank Account 1 — [Bank Name] (bankAccount, owner: user)
   - Bank Account 2 — [Bank Name] (bankAccount, owner: user)
   - Yousuf's Money (childProtectedFund, owner: child)
   - Gold Savings (goldHolding, owner: user)
6. For each account Ahmad enters an opening balance (recorded as `openingBalance` ledger entry).
7. Ahmad sees the dashboard: all accounts listed, total net worth, total available.
8. Onboarding complete.

### Financial invariants checked

- Each opening balance creates exactly one credit ledger entry per account.
- Net worth immediately reflects total opening balances minus any liabilities.
- No account starts with a derived balance that was not explicitly entered.

---

## Journey 2 — Give Money to Spouse for Groceries

**Actor:** Ahmad  
**Goal:** Give Hana 2,000 EGP from home savings for household purchases

### Steps

1. Ahmad taps "New Transfer" or uses quick-action on Home Savings account.
2. Source: Home Savings | Destination: Wife Wallet | Amount: 2,000 EGP.
3. Notes: "Supermarket + pharmacy run."
4. Ahmad confirms. Operation is atomic.
5. Home Savings balance decreases by 2,000 EGP.
6. Wife Wallet balance increases by 2,000 EGP.
7. Dashboard shows spouse wallet balance: 2,000 EGP.

### Later — Hana reports spending

8. Ahmad opens Spouse section.
9. Taps "Record Spouse Expense."
10. Amount: 1,300 EGP | Category: Groceries | Scope: Household | Spender: Spouse | Beneficiary: Household | From: Wife Wallet.
11. Amount: 500 EGP | Category: Healthcare | Scope: Household | Spender: Spouse | Beneficiary: Child | From: Wife Wallet.
12. Wife Wallet balance: 2,000 − 1,300 − 500 = 200 EGP.

### Later — Hana returns unused money

13. Ahmad taps "Return Spouse Money."
14. Transfer: Wife Wallet → Home Savings | Amount: 200 EGP.
15. Wife Wallet balance: 0 EGP.
16. Home Savings restored by 200 EGP.

### Financial invariants checked

- Net worth does not change during any transfer step.
- Wife Wallet balance is always: transfers_in − expenses − transfers_out.
- No money is lost or created.

---

## Journey 3 — Receive Salary and Pay Bills

**Actor:** Ahmad  
**Goal:** Record monthly salary receipt and pay utility bills

### Steps

1. Ahmad taps "Add Income."
2. Category: Salary | Amount: 25,000 EGP | To: Bank Account 1 | Scope: Personal | Date: first of month.
3. Bank Account 1 balance increases by 25,000 EGP.
4. Dashboard net worth increases by 25,000 EGP.
5. Ahmad taps "Add Expense" for electricity bill.
6. Amount: 800 EGP | Category: Utilities | From: Bank Account 1 | Scope: Household | Spender: User | Beneficiary: Household.
7. Repeat for internet, water, gas.
8. Reports show total household utility spending for the month.

---

## Journey 4 — Create a Bank Certificate

**Actor:** Ahmad  
**Goal:** Move 50,000 EGP from Bank Account 1 into a 12-month certificate

### Steps

1. Ahmad opens Bank Account 1.
2. Taps "Create Certificate."
3. Fills certificate form: Name "Certificate Jan 2026", Rate: 22% annual, Payout: monthly to Bank Account 1.
4. Source: Bank Account 1 | Principal: 50,000 EGP.
5. Ahmad confirms.
6. System performs atomic operation:
   - Debit Bank Account 1 by 50,000 EGP (ledger type: certificateFunding).
   - Create certificate position with principal 50,000 EGP.
7. Bank Account 1 available balance: reduced by 50,000 EGP.
8. Certificate balance: 50,000 EGP.
9. Net worth: unchanged (50,000 moved from bank to certificate asset).

### Monthly interest payout

10. On payout date, Ahmad taps "Record Interest."
11. Amount: 916.67 EGP rounded to nearest piaster → stored as 91,667 minor units.
12. Ledger type: interestIncome | To: Bank Account 1.
13. Bank Account 1 balance increases.
14. Net worth increases by interest amount.

### Maturity

15. At maturity date, Ahmad taps "Mature Certificate."
16. System: returns 50,000 EGP principal to Bank Account 1 (ledger type: certificateMaturity).
17. Final interest recorded separately.
18. Certificate marked as matured.
19. Historical record preserved.

### Financial invariants checked

- At no point is 50,000 EGP counted in both Bank Account 1 and the certificate.
- Net worth is unchanged at certificate creation.
- Net worth increases only at interest payout.

---

## Journey 5 — Record Child Gift Money and Protect It

**Actor:** Ahmad  
**Goal:** Record 3,000 EGP in Eid gifts received by Yousuf

### Steps

1. Ahmad opens "Child Funds" section.
2. Taps "Add Child Income."
3. Category: ChildGift | Amount: 3,000 EGP | To: Yousuf's Money (childProtectedFund) | Date: Eid day | Source: Grandparents.
4. Yousuf's Money balance: 3,000 EGP.
5. Dashboard shows child-protected total: 3,000 EGP.

### Later — Emergency: Ahmad needs to withdraw

6. Ahmad taps "Withdraw from Child Funds."
7. App shows warning (Arabic):

```
⚠️ هذا المال محجوز ليوسف.
سيُسجَّل سحب هذا المبلغ بشكل دائم ولا يمكن حذفه.
يرجى ذكر سبب السحب قبل المتابعة.
```

8. Ahmad enters reason: "Emergency pharmacy — Yousuf's medication not covered by insurance."
9. Beneficiary: Child (Yousuf).
10. Confirmation tap required.
11. Optional: biometric or PIN re-authentication.
12. System records: withdrawal amount, reason, beneficiary, operator (user), timestamp.
13. Audit history is permanent and visible.

### Financial invariants checked

- Child funds cannot be spent without the warning and reason being recorded.
- The audit entry is immutable.
- Child-fund balance is always: deposits − withdrawals (with reasons).

---

## Journey 6 — Buy Gold

**Actor:** Ahmad  
**Goal:** Buy 10 grams of 21k gold using home savings

### Steps

1. Ahmad opens Gold section.
2. Taps "Buy Gold."
3. Fields: Gold type: Jewelry | Karat: 21 | Weight: 10g | Purchase price: 32,000 EGP total | Making charges: 800 EGP | From: Home Savings.
4. Confirm.
5. System:
   - Debits Home Savings: 32,800 EGP (principal 32,000 + fee 800).
   - Creates gold position: 10g @ 3,200 EGP/g.
   - Records making charges as expense (category: Fees).
6. Gold holding balance: 32,000 EGP purchase value.
7. Net worth: unchanged (32,000 moved from savings to gold asset; 800 EGP fee reduces net worth).

### Price update

8. Current gold price rises. Ahmad taps "Update Price."
9. Enters: 3,500 EGP/g.
10. Gold current value: 35,000 EGP.
11. Unrealized gain: +3,000 EGP.
12. Net worth increases by unrealized gain.

### Selling gold

13. Ahmad sells 5g of gold.
14. Sale proceeds: 17,500 EGP.
15. System:
    - Reduces gold position by 5g.
    - Deposits 17,500 EGP to selected account.
    - Calculates realized gain: (17,500 − 16,000) = 1,500 EGP.
    - Records realized gain.
16. Audit history preserved.

---

## Journey 7 — Monthly Budget Review

**Actor:** Ahmad  
**Goal:** Review spending at end of month

### Steps

1. Ahmad opens Reports.
2. Selects: Current Month.
3. Dashboard shows:
   - Personal spending: 4,200 EGP
   - Household spending: 8,700 EGP
   - Child spending: 1,100 EGP
   - Spouse spending from wife wallet: 2,300 EGP
4. Budget comparison: household budget 9,000 EGP → 96.7% used.
5. Drill down: top categories → Groceries 3,200, Utilities 2,100, Healthcare 1,800.
6. Transfers are excluded from all spending totals.
7. Ahmad sees he's 300 EGP under budget.

---

## Journey 8 — Offline Transaction then Sync

**Actor:** Ahmad  
**Goal:** Record transactions with no internet, then sync

### Steps

1. Ahmad is in an area with no connectivity.
2. He records:
   - Expense: 150 EGP, Groceries, Personal Cash.
   - Transfer: Personal Cash → Home Savings, 500 EGP.
3. App shows sync indicator: "2 pending, offline."
4. All operations saved locally with stable UUID and timestamp.
5. Ahmad regains connectivity.
6. Sync queue processes in order, idempotently.
7. If server rejects a duplicate (same operation ID), client marks it as synced.
8. Dashboard shows "All synced."

---

## Journey 9 — Zakat Calculation

**Actor:** Ahmad  
**Goal:** Calculate zakat at end of hawl year

### Steps

1. Ahmad opens Zakat section.
2. Sets hawl date: one year ago.
3. Configures which assets to include:
   - ✅ Bank Account 1
   - ✅ Bank Account 2
   - ✅ Home Savings
   - ✅ Gold (zakatable weight calculated from 21k karat)
   - ✅ Certificate — principal only
   - ❌ Personal cash wallet (below nisab? user decides)
   - ❌ Yousuf's money (user decides)
4. Configures liabilities to deduct:
   - Car installment outstanding: 15,000 EGP
5. App shows:
   - Total zakatable assets: X EGP
   - Deducted liabilities: 15,000 EGP
   - Net zakatable amount: Y EGP
   - Nisab (gold or silver basis, user selects): Z EGP
   - Zakat due (2.5%): W EGP
6. Disclaimer shown: "This is a calculation aid only. Consult a qualified scholar for your specific situation."
7. Ahmad records zakat payment as sadaqah expense linked to zakat calculation.

---

## Journey 10 — Voice Entry (Arabic, Optional AI)

**Actor:** Ahmad  
**Goal:** Quickly record a complex household transaction using voice

### Steps

1. Ahmad taps microphone button.
2. Speaks (Arabic): "مراتي خدت ألفين من مدخرات البيت وجابت طلبات بألف وثلاثمية"
3. AI processes and proposes (pending user review):

   ```
   عملية 1 — تحويل
   من: مدخرات البيت → محفظة زوجتي
   المبلغ: 2,000 جنيه

   عملية 2 — مصروف
   من: محفظة زوجتي
   المبلغ: 1,300 جنيه
   التصنيف: مشتريات
   النطاق: الأسرة
   المنفق: الزوجة

   الرصيد المتبقي في محفظة الزوجة: 700 جنيه
   ```

4. Ahmad reviews the proposed operations.
5. Taps "Confirm" to save both.
6. Both operations recorded atomically.
7. If Ahmad rejects, nothing is saved.

### AI constraints

- AI output is treated as untrusted structured input.
- Validated against strict Dart schema before display.
- Never written to database without user confirmation.
- App works identically without AI.

---

## Journey 11 — App Lock and Biometric Unlock

**Actor:** Ahmad  
**Goal:** Protect financial data on his phone

### Steps

1. Ahmad enables PIN lock in Settings.
2. Sets 6-digit PIN.
3. Enables biometric unlock (fingerprint).
4. Sets auto-lock: 2 minutes after backgrounding.
5. Ahmad switches apps; 2 minutes later returns.
6. App shows lock screen with blur over previous content.
7. Ahmad uses fingerprint → unlocked.
8. Ahmad enters wrong PIN 3 times → exponential backoff.
9. App switcher shows blurred preview (screenshot protection).

---

## Journey 12 — Backup and Restore

**Actor:** Ahmad  
**Goal:** Create encrypted backup before phone upgrade

### Steps

1. Ahmad opens Settings → Backup.
2. Taps "Create Backup."
3. Enters backup password.
4. Backup file created: `fmm_backup_20260715.fmmbak` (AES-256 encrypted).
5. Ahmad exports to Files or Google Drive.
6. On new phone: installs app, opens Settings → Restore.
7. Selects backup file, enters password.
8. Import preview shown: account count, transaction count, date range.
9. Ahmad confirms replace (auto-backup of empty state taken first).
10. Data restored. Ahmad verifies account balances match expectations.
