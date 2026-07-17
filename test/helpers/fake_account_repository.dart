import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// In-memory fake implementation of [AccountRepository] for widget and unit tests.
final class FakeAccountRepository implements AccountRepository {
  final List<FinancialAccount> _accounts = [];

  @override
  Future<FinancialAccount> createAccount(CreateAccountParams params) async {
    if (_accounts.any((a) => a.id == params.id)) {
      throw DuplicateAccountIdError(params.id);
    }
    final account = FinancialAccount(
      id: params.id,
      householdId: params.householdId,
      name: params.name,
      type: params.type,
      ownerType: params.ownerType,
      fundPurpose: params.fundPurpose,
      currencyCode: params.currencyCode,
      isSpendable: params.isSpendable,
      isProtected: params.isProtected,
      includeInNetWorth: params.includeInNetWorth,
      includeInZakat: params.includeInZakat,
      isArchived: false,
      displayOrder: params.displayOrder,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      createdBy: params.createdBy,
      notes: params.notes,
    );
    _accounts.add(account);
    if (params.idempotencyKey != null) {
      _idempotencyKeys['${params.householdId}/${params.idempotencyKey}'] = params.id;
    }
    return account;
  }

  @override
  Future<FinancialAccount?> findById({required String id, required String householdId}) async =>
      _accounts.where((a) => a.id == id && a.householdId == householdId).firstOrNull;

  // Stores idempotency key → account id for idempotency testing.
  final Map<String, String> _idempotencyKeys = {}; // '$householdId/$key' → accountId

  @override
  Future<FinancialAccount?> findByIdempotencyKey({
    required String householdId,
    required String idempotencyKey,
  }) async {
    final mapKey = '$householdId/$idempotencyKey';
    final accountId = _idempotencyKeys[mapKey];
    if (accountId == null) return null;
    return _accounts.where((a) => a.id == accountId).firstOrNull;
  }

  @override
  Future<List<FinancialAccount>> findByHousehold({
    required String householdId,
    bool includeArchived = false,
  }) async => _accounts
      .where((a) => a.householdId == householdId && (includeArchived || !a.isArchived))
      .toList();

  @override
  Future<bool> hasOpeningBalance({required String accountId, required String householdId}) async =>
      false;

  @override
  Future<FinancialAccount> archiveAccount({
    required String id,
    required String householdId,
    required DateTime archivedAt,
    required String updatedAt,
  }) async {
    final idx = _accounts.indexWhere((a) => a.id == id && a.householdId == householdId);
    if (idx < 0) throw AccountNotFoundError(id);
    if (_accounts[idx].isArchived) throw AccountAlreadyArchivedError(id);
    final archived = _accounts[idx].copyWith(isArchived: true);
    _accounts[idx] = archived;
    return archived;
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
    final idx = _accounts.indexWhere((a) => a.id == id && a.householdId == householdId);
    if (idx < 0) throw AccountNotFoundError(id);
    final updated = _accounts[idx].copyWith(
      name: name,
      isSpendable: isSpendable,
      isProtected: isProtected,
      includeInNetWorth: includeInNetWorth,
      includeInZakat: includeInZakat,
      displayOrder: displayOrder,
      notes: notes,
      metadata: metadata,
      updatedAt: updatedAt,
    );
    _accounts[idx] = updated;
    return updated;
  }
}
