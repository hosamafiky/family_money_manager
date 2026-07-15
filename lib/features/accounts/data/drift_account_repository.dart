import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// Drift-backed implementation of [AccountRepository].
///
/// Maps between [FinancialAccount] domain objects and Drift-generated
/// [FinancialAccountsData] rows. No domain logic is performed here.
final class DriftAccountRepository implements AccountRepository {
  const DriftAccountRepository(this._db);

  final AppDatabase _db;

  @override
  Future<FinancialAccount> createAccount(CreateAccountParams params) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final companion = FinancialAccountsCompanion.insert(
      id: params.id,
      householdId: params.householdId,
      name: params.name,
      type: params.type.code,
      ownerType: params.ownerType.code,
      // Fields with table defaults use Value<T> in Drift 2.x insert constructors.
      fundPurpose: Value(params.fundPurpose.code),
      currencyCode: Value(params.currencyCode),
      isSpendable: Value(params.isSpendable),
      isProtected: Value(params.isProtected),
      includeInNetWorth: Value(params.includeInNetWorth),
      includeInZakat: Value(params.includeInZakat),
      displayOrder: Value(params.displayOrder),
      createdBy: params.createdBy,
      createdAt: now,
      updatedAt: now,
      notes: Value(params.notes),
      metadata: Value(
        params.metadata != null ? jsonEncode(params.metadata) : null,
      ),
    );

    try {
      await _db.into(_db.financialAccounts).insert(companion);
    } on Exception catch (e) {
      if (e.toString().contains('UNIQUE constraint')) {
        throw DuplicateAccountIdError(params.id);
      }
      rethrow;
    }

    return _toAccount(
      await (_db.select(
        _db.financialAccounts,
      )..where((t) => t.id.equals(params.id))).getSingle(),
    );
  }

  @override
  Future<FinancialAccount?> findById({
    required String id,
    required String householdId,
  }) async {
    final row =
        await (_db.select(_db.financialAccounts)..where(
              (t) => t.id.equals(id) & t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    return row == null ? null : _toAccount(row);
  }

  @override
  Future<List<FinancialAccount>> findByHousehold({
    required String householdId,
    bool includeArchived = false,
  }) async {
    final query = _db.select(_db.financialAccounts)
      ..where((t) {
        final base = t.householdId.equals(householdId);
        return includeArchived ? base : base & t.isArchived.equals(false);
      })
      ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]);

    final rows = await query.get();
    return rows.map(_toAccount).toList();
  }

  @override
  Future<bool> hasOpeningBalance({
    required String accountId,
    required String householdId,
  }) async {
    final count =
        await (_db.select(_db.ledgerEntries)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.householdId.equals(householdId) &
                  t.entryType.equals('openingBalance'),
            ))
            .get();
    return count.isNotEmpty;
  }

  @override
  Future<FinancialAccount> archiveAccount({
    required String id,
    required String householdId,
    required DateTime archivedAt,
    required String updatedAt,
  }) async {
    final existing = await findById(id: id, householdId: householdId);
    if (existing == null) throw AccountNotFoundError(id);
    if (existing.isArchived) throw AccountAlreadyArchivedError(id);

    await (_db.update(
      _db.financialAccounts,
    )..where((t) => t.id.equals(id) & t.householdId.equals(householdId))).write(
      FinancialAccountsCompanion(
        isArchived: const Value(true),
        archivedAt: Value(archivedAt.toUtc().toIso8601String()),
        updatedAt: Value(updatedAt),
      ),
    );

    return _toAccount(
      await (_db.select(
        _db.financialAccounts,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  @override
  Future<FinancialAccount> updateAccount({
    required String id,
    required String householdId,
    String? name,
    bool? isSpendable,
    bool? isProtected,
    bool? includeInNetWorth,
    bool? includeInZakat,
    int? displayOrder,
    String? notes,
    Map<String, dynamic>? metadata,
    required String updatedAt,
  }) async {
    final existing = await findById(id: id, householdId: householdId);
    if (existing == null) throw AccountNotFoundError(id);

    await (_db.update(
      _db.financialAccounts,
    )..where((t) => t.id.equals(id) & t.householdId.equals(householdId))).write(
      FinancialAccountsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        isSpendable: isSpendable != null
            ? Value(isSpendable)
            : const Value.absent(),
        isProtected: isProtected != null
            ? Value(isProtected)
            : const Value.absent(),
        includeInNetWorth: includeInNetWorth != null
            ? Value(includeInNetWorth)
            : const Value.absent(),
        includeInZakat: includeInZakat != null
            ? Value(includeInZakat)
            : const Value.absent(),
        displayOrder: displayOrder != null
            ? Value(displayOrder)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        metadata: metadata != null
            ? Value(jsonEncode(metadata))
            : const Value.absent(),
        updatedAt: Value(updatedAt),
      ),
    );

    return _toAccount(
      await (_db.select(
        _db.financialAccounts,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  // ── Mapper ────────────────────────────────────────────────────────────────

  FinancialAccount _toAccount(DbFinancialAccount row) {
    return FinancialAccount(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      type: FinancialAccountType.fromCode(row.type),
      ownerType: AccountOwnerType.fromCode(row.ownerType),
      fundPurpose: FundPurpose.fromCode(row.fundPurpose),
      currencyCode: row.currencyCode,
      isSpendable: row.isSpendable,
      isProtected: row.isProtected,
      includeInNetWorth: row.includeInNetWorth,
      includeInZakat: row.includeInZakat,
      isArchived: row.isArchived,
      archivedAt: row.archivedAt != null
          ? DateTime.tryParse(row.archivedAt!)?.toUtc()
          : null,
      displayOrder: row.displayOrder,
      notes: row.notes,
      metadata: row.metadata != null
          ? Map<String, dynamic>.from(jsonDecode(row.metadata!) as Map)
          : null,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      createdBy: row.createdBy,
    );
  }
}
