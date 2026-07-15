# User Personas

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## Persona 1 — Ahmad (Primary User)

**Name:** Ahmad  
**Age:** 34  
**Occupation:** Engineer, mid-senior level  
**Income:** Monthly salary deposited to Bank Account 1; occasional freelance payments to Bank Account 2  
**Family:** Married to Hana; one child, Yousuf (age 4)  
**Technical literacy:** High — comfortable with smartphones and apps, but not a developer  
**Language preference:** Arabic first; reads English comfortably  
**Devices:** Android phone (primary), occasionally iPad

### Financial situation

Ahmad has the following financial locations:

| Location                        | Type               | Purpose                              |
| ------------------------------- | ------------------ | ------------------------------------ |
| Personal cash in wallet         | personalCashWallet | Day-to-day personal spending         |
| Bank Account 1 (salary)         | bankAccount        | Salary deposits, household bills     |
| Bank Account 2 (freelance)      | bankAccount        | Secondary income, savings overflow   |
| Certificate — Bank 1 (12-month) | certificate        | Medium-term savings earning interest |
| Home cash savings               | homeSavingsCash    | Emergency and family buffer          |
| Wife wallet                     | spouseCashWallet   | Household shopping, spouse spending  |
| Yousuf's gift money             | childProtectedFund | Money received as gifts for Yousuf   |
| Gold (21k, 50g)                 | goldHolding        | Long-term store of value             |

### Goals and worries

- **Primary worry:** He gives Hana cash for shopping but cannot track what was spent and what remains.
- **Secondary worry:** He doesn't know his real net worth when certificates, gold, and savings are combined.
- **Goal:** Build an emergency fund of 50,000 EGP, then save for a new car (350,000 EGP target).
- **Religious concern:** He wants to calculate zakat accurately across all asset types each year.
- **Child concern:** Yousuf receives gift money from relatives. Ahmad wants to protect it and never accidentally spend it.

### Key jobs the app must do for Ahmad

1. Show him exactly how much total money the household has right now.
2. Let him record giving Hana cash quickly and see what she spent vs. what remains.
3. Let him record his child's gift income and protect it.
4. Warn him loudly before he touches Yousuf's money.
5. Show him that his certificate's principal is NOT in his bank available balance.
6. Track gold value and unrealized gains.
7. Calculate zakat at the end of the hawl year.
8. Show spending by category, by month, by beneficiary (personal vs. household vs. child).

### Frustrations with existing tools

- Generic expense apps show everything as income/expense, confusing transfers with real spending.
- Bank apps only show one account at a time.
- Spreadsheets lose track of money movement history.
- Cash is invisible in digital tools.

---

## Persona 2 — Hana (Spouse, Indirect User)

**Name:** Hana  
**Age:** 31  
**Occupation:** Stay-at-home mother  
**Financial role:** Manages household daily spending; receives cash from Ahmad for groceries, utilities, children's needs  
**Technical literacy:** Moderate — uses WhatsApp and Instagram comfortably  
**Language preference:** Arabic

### How Hana interacts with the app (v1)

Hana does **not** have a separate login in v1. Ahmad records all transactions on her behalf.

However, the system models Hana as a **household member** with her own spending wallet, so her spending is tracked accurately.

Ahmad can:

- Record money given to Hana → Transfer: Home Savings → Wife Wallet
- Record what Hana spent → Expense: Wife Wallet, Spender: Spouse
- Record what Hana returned → Transfer: Wife Wallet → Home Savings
- See Hana's wallet balance at any time

**v2 consideration:** Hana gets read-only or limited write access from her own phone.

---

## Persona 3 — Yousuf (Child, Protected Beneficiary)

**Name:** Yousuf  
**Age:** 4  
**Role:** Financial beneficiary; his money is held in trust by his parents

### Child financial model

Yousuf does not use the app. His money is stored in one or more `childProtectedFund` accounts.

Sources of his money:

- Eid gifts (cash)
- Birthday gifts (cash or bank transfer)
- Grandparents' regular gifts
- Any future child allowance

The application treats Yousuf's money as a protected asset. It is included in household net worth only if Ahmad opts in. It is never silently used for household expenses.

Any withdrawal from Yousuf's accounts requires:

1. A warning shown to Ahmad
2. A typed reason
3. Explicit confirmation
4. A permanent audit entry with date, amount, reason, and operator

---

## Persona 4 — Future Spouse User (v2 Placeholder)

Not implemented in v1. Placeholder in architecture to ensure the data model supports multi-member household access.

Requirements for v2 consideration:

- Separate authentication
- Scoped write access (spouse can add household expenses only)
- Shared read access to household accounts
- Cannot access personal accounts of primary user
- Cannot withdraw from child-protected funds without primary-user confirmation

---

## Household Financial Context Summary

| Asset type           | Who owns it      | Who manages it | Protected?   |
| -------------------- | ---------------- | -------------- | ------------ |
| Personal cash wallet | User             | User           | No           |
| Bank accounts        | User             | User           | No           |
| Home savings         | Household        | User           | Configurable |
| Spouse wallet        | Spouse           | User (v1)      | No           |
| Child gift money     | Child            | User           | Yes          |
| Certificates         | User             | User           | No           |
| Gold                 | User / Household | User           | No           |
| Goals                | Household        | User           | Configurable |
| Emergency fund       | Household        | User           | Yes          |
