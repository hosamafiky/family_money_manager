import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_calculator.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/balance/domain/balance_repository.dart';

/// Drift-backed implementation of [BalanceRepository].
///
/// Balances are computed from ledger entries on every call.
/// No mutable balance field is read or written (FINANCIAL_MODEL §3).
final class DriftBalanceRepository implements BalanceRepository {
  const DriftBalanceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> currentBalanceMinorUnits({
    required String accountId,
    required String householdId,
  }) async {
    final account = await _getAccount(accountId, householdId);
    if (account == null) return 0; // unknown account in this household → 0
    final entries = await _loadEntries(accountId, householdId);
    final currency = Currency.fromCode(account.currencyCode);
    return LedgerCalculator.balance(
      accountId: accountId,
      entries: entries,
      currency: currency,
    ).minorUnits;
  }

  @override
  Future<int> historicalBalanceMinorUnits({
    required String accountId,
    required String householdId,
    required String asOfDate,
  }) async {
    final account = await _getAccount(accountId, householdId);
    if (account == null) return 0;
    final entries = await _loadEntries(accountId, householdId);
    final currency = Currency.fromCode(account.currencyCode);
    return LedgerCalculator.historicalBalance(
      accountId: accountId,
      entries: entries,
      currency: currency,
      asOfDate: asOfDate,
    ).minorUnits;
  }

  @override
  Future<List<AccountBalance>> netWorthBalances({
    required String householdId,
  }) async {
    final accounts =
        await (_db.select(_db.financialAccounts)..where(
              (t) =>
                  t.householdId.equals(householdId) &
                  t.isArchived.equals(false) &
                  t.includeInNetWorth.equals(true),
            ))
            .get();

    final result = <AccountBalance>[];
    for (final account in accounts) {
      final entries = await _loadEntries(account.id, householdId);
      final currency = Currency.fromCode(account.currencyCode);
      final balance = LedgerCalculator.balance(
        accountId: account.id,
        entries: entries,
        currency: currency,
      );
      result.add(AccountBalance(accountId: account.id, balance: balance));
    }
    return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<LedgerEntryRecord>> _loadEntries(
    String accountId,
    String householdId,
  ) async {
    final rows =
        await (_db.select(_db.ledgerEntries)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.householdId.equals(householdId),
            ))
            .get();

    return rows
        .map(
          (r) => LedgerEntryRecord(
            id: r.id,
            accountId: r.accountId,
            direction: LedgerDirection.fromCode(r.direction),
            amountMinorUnits: r.amountMinorUnits,
            currencyCode: r.currencyCode,
            entryType: LedgerEntryType.fromCode(r.entryType),
            effectiveDate: r.effectiveDate,
            isReversal: r.isReversal,
            reversalOfEntryId: r.reversalOfEntryId,
          ),
        )
        .toList();
  }

  Future<DbFinancialAccount?> _getAccount(
    String accountId,
    String householdId,
  ) async {
    return (_db.select(_db.financialAccounts)..where(
          (t) => t.id.equals(accountId) & t.householdId.equals(householdId),
        ))
        .getSingleOrNull();
  }
}
