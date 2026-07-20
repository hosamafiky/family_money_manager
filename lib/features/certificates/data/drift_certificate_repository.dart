import 'package:drift/drift.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/scoped_idempotency.dart';
import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/data/certificate_repository.dart';
import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart'
    show InsufficientFundsError;
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Drift-backed [CertificateRepository] (Phase 6A).
final class DriftCertificateRepository implements CertificateRepository {
  DriftCertificateRepository(
    this._db, {
    @visibleForTesting
    CertificateFailAfter debugFailAfter = CertificateFailAfter.none,
    @visibleForTesting Future<void> Function()? debugTransactionBarrier,
  }) : _debugFailAfter = debugFailAfter,
       _debugTransactionBarrier = debugTransactionBarrier;

  final AppDatabase _db;
  final CertificateFailAfter _debugFailAfter;
  final Future<void> Function()? _debugTransactionBarrier;

  Future<void> _failAfter(CertificateFailAfter step) async {
    if (_debugFailAfter == step && step != CertificateFailAfter.none) {
      throw CertificateInjectedFailure(step);
    }
  }

  Future<void> _awaitBarrier() async {
    final barrier = _debugTransactionBarrier;
    if (barrier != null) await barrier();
  }

  // ── createCertificate ─────────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsCertificate>> createCertificate({
    required SavingsCertificate certificate,
    required CertificateRevision initialRevision,
    required FinancialAccount certificateAccount,
    required CertificatePurchaseFunding purchase,
  }) async {
    if (purchase.amountMinorUnits <= 0 ||
        purchase.amountMinorUnits != certificate.originalPrincipalMinorUnits) {
      return const AppValidationFailure(
        field: 'principalMinorUnits',
        messageKey: 'errorCertificatePrincipalZero',
      );
    }

    final incomingPayload = buildCertificateIdempotencyPayload(
      householdId: certificate.householdId,
      institutionName: initialRevision.institutionName,
      reference: initialRevision.reference,
      currencyCode: certificate.currencyCode,
      principalMinorUnits: certificate.originalPrincipalMinorUnits,
      startDate: certificate.startDate,
      maturityDate: certificate.maturityDate,
      annualRateBps: initialRevision.annualRateBps,
      profitFrequency: initialRevision.profitFrequency,
      sourceAccountId: purchase.sourceAccountId,
    );

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        AppResult<SavingsCertificate>? early;

        try {
          await _db.transaction(() async {
            // 1. Idempotency lookup (after writer lock — recalculated each retry)
            final existing = await _db
                .customSelect(
                  'SELECT id, idempotency_payload FROM savings_certificates '
                  'WHERE household_id = ? AND idempotency_key = ?',
                  variables: [
                    Variable.withString(certificate.householdId),
                    Variable.withString(certificate.idempotencyKey),
                  ],
                )
                .get();

            if (existing.isNotEmpty) {
              final row = existing.first;
              final stored = row.read<String>('idempotency_payload');
              if (stored == incomingPayload) {
                final found = await _findById(row.read<String>('id'));
                early = found != null
                    ? AppOk(found)
                    : const AppPersistenceFailure();
              } else {
                early = const AppDuplicateConflict(
                  messageKey: 'errorCertificateIdempotencyConflict',
                );
              }
              return;
            }

            await _failAfter(CertificateFailAfter.idempotencyLookup);
            await _awaitBarrier();

            // 4–5. Validate funding source + funds
            final srcRows = await _db
                .customSelect(
                  'SELECT id, currency_code, is_archived, type, is_protected '
                  'FROM financial_accounts WHERE id = ? AND household_id = ?',
                  variables: [
                    Variable.withString(purchase.sourceAccountId),
                    Variable.withString(certificate.householdId),
                  ],
                )
                .get();
            if (srcRows.isEmpty) {
              early = const AppNotFound();
              return;
            }
            final src = srcRows.first;
            if (src.read<int>('is_archived') == 1) {
              early = const AppValidationFailure(
                field: 'sourceAccountId',
                messageKey: 'errorAccountArchived',
              );
              return;
            }
            if (src.read<int>('is_protected') == 1) {
              early = const AppValidationFailure(
                field: 'sourceAccountId',
                messageKey: 'errorCertificateSourceProtected',
              );
              return;
            }
            final srcType = src.read<String>('type');
            if (srcType == 'goalReserve' || srcType == 'certificate') {
              early = const AppValidationFailure(
                field: 'sourceAccountId',
                messageKey: 'errorCertificateSourceInvalid',
              );
              return;
            }
            if (src.read<String>('currency_code') != certificate.currencyCode) {
              early = const AppValidationFailure(
                field: 'currencyCode',
                messageKey: 'errorCurrencyMismatch',
              );
              return;
            }

            final balRows = await _db
                .customSelect(
                  'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
                  'ELSE -amount_minor_units END), 0) AS bal '
                  'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
                  variables: [
                    Variable.withString(LedgerDirection.credit.code),
                    Variable.withString(purchase.sourceAccountId),
                    Variable.withString(certificate.householdId),
                  ],
                )
                .get();
            final sourceBalance = balRows.first.read<int>('bal');
            if (sourceBalance < purchase.amountMinorUnits) {
              throw InsufficientFundsError(
                accountId: purchase.sourceAccountId,
                availableMinorUnits: sourceBalance,
                requestedMinorUnits: purchase.amountMinorUnits,
              );
            }

            // 5. Certificate account
            await _db
                .into(_db.financialAccounts)
                .insert(
                  FinancialAccountsCompanion.insert(
                    id: certificateAccount.id,
                    householdId: certificateAccount.householdId,
                    name: certificateAccount.name,
                    type: certificateAccount.type.code,
                    ownerType: certificateAccount.ownerType.code,
                    fundPurpose: Value(certificateAccount.fundPurpose.code),
                    currencyCode: Value(certificateAccount.currencyCode),
                    isSpendable: Value(certificateAccount.isSpendable),
                    isProtected: Value(certificateAccount.isProtected),
                    includeInNetWorth: Value(
                      certificateAccount.includeInNetWorth,
                    ),
                    includeInZakat: Value(certificateAccount.includeInZakat),
                    displayOrder: Value(certificateAccount.displayOrder),
                    createdBy: certificateAccount.createdBy,
                    createdAt: certificateAccount.createdAt,
                    updatedAt: certificateAccount.updatedAt,
                  ),
                );
            await _failAfter(CertificateFailAfter.accountInsert);

            // 6. Certificate row
            await _db
                .into(_db.savingsCertificatesTable)
                .insert(
                  SavingsCertificatesTableCompanion.insert(
                    id: certificate.id,
                    householdId: certificate.householdId,
                    certificateAccountId: certificate.certificateAccountId,
                    currencyCode: certificate.currencyCode,
                    originalPrincipalMinorUnits:
                        certificate.originalPrincipalMinorUnits,
                    startDate: certificate.startDate,
                    maturityDate: certificate.maturityDate,
                    lifecycle: certificate.lifecycle.name,
                    idempotencyKey: certificate.idempotencyKey,
                    idempotencyPayload: incomingPayload,
                    createdAt: certificate.createdAt,
                    redeemedAt: Value(certificate.redeemedAt),
                    archivedAt: Value(certificate.archivedAt),
                    schemaVersion: Value(certificate.schemaVersion),
                  ),
                );
            await _failAfter(CertificateFailAfter.certificateInsert);

            // 7. Initial revision
            await _insertRevision(initialRevision);
            await _failAfter(CertificateFailAfter.revisionInsert);

            // 8–11. Purchase transfer op + legs + context
            final now = DateTime.now().toUtc().toIso8601String();
            await _db.customStatement(
              'INSERT INTO operations '
              '(id, household_id, type, effective_date, recorded_at, '
              'total_amount_minor_units, currency_code, created_by, created_at, '
              'updated_at, description, source_account_id, destination_account_id, '
              'idempotency_key) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                purchase.operationId,
                certificate.householdId,
                OperationType.certificateFunding.code,
                purchase.effectiveDate,
                now,
                purchase.amountMinorUnits,
                purchase.currencyCode,
                'system',
                now,
                now,
                purchase.description,
                purchase.sourceAccountId,
                certificate.certificateAccountId,
                purchase.idempotencyKey,
              ],
            );
            await _failAfter(CertificateFailAfter.operationInsert);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${purchase.operationId}_debit',
                purchase.operationId,
                certificate.householdId,
                purchase.sourceAccountId,
                LedgerDirection.debit.code,
                purchase.amountMinorUnits,
                purchase.currencyCode,
                LedgerEntryType.transferOut.code,
                purchase.effectiveDate,
                now,
                'system',
              ],
            );
            await _failAfter(CertificateFailAfter.firstLedgerEntry);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${purchase.operationId}_credit',
                purchase.operationId,
                certificate.householdId,
                certificate.certificateAccountId,
                LedgerDirection.credit.code,
                purchase.amountMinorUnits,
                purchase.currencyCode,
                LedgerEntryType.transferIn.code,
                purchase.effectiveDate,
                now,
                'system',
              ],
            );
            await _failAfter(CertificateFailAfter.secondLedgerEntry);

            await _db.customStatement(
              'INSERT INTO operation_contexts '
              '(operation_id, household_id, is_recurring, note, created_at) '
              'VALUES (?, ?, 0, ?, ?)',
              [
                purchase.operationId,
                certificate.householdId,
                purchase.description,
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.operationContext);

            // 12. Purchase + created events
            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, NULL, ?, ?, 1)',
              [
                _uuid.v4(),
                certificate.id,
                certificate.householdId,
                CertificateEventType.created.code,
                purchase.eventCreatedAt,
                purchase.eventCreatedAt,
              ],
            );
            await _failAfter(CertificateFailAfter.createdEvent);

            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
              [
                purchase.eventId,
                certificate.id,
                certificate.householdId,
                CertificateEventType.purchased.code,
                purchase.operationId,
                purchase.amountMinorUnits,
                purchase.currencyCode,
                'purchase-${purchase.idempotencyKey}',
                incomingPayload,
                purchase.description,
                purchase.eventCreatedAt,
                purchase.eventCreatedAt,
              ],
            );
            await _failAfter(CertificateFailAfter.purchasedEvent);
            await _failAfter(CertificateFailAfter.eventInsert);
            await _failAfter(CertificateFailAfter.preCommit);
          });

          if (early != null) return early!;
          return AppOk(certificate);
        } on InsufficientFundsError {
          return const AppInsufficientFunds();
        } on CertificateInjectedFailure {
          return const AppPersistenceFailure();
        } catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isRetryableSqliteContention(e)) rethrow;
          // After UNIQUE / lock race where winner already committed, re-read.
          final recovered = await _resolveCertificateIdempotency(
            householdId: certificate.householdId,
            idempotencyKey: certificate.idempotencyKey,
            incomingPayload: incomingPayload,
          );
          if (recovered != null) return recovered;
          return const AppPersistenceFailure();
        }
      });
    } on SqliteContentionExhausted {
      final recovered = await _resolveCertificateIdempotency(
        householdId: certificate.householdId,
        idempotencyKey: certificate.idempotencyKey,
        incomingPayload: incomingPayload,
      );
      if (recovered != null) return recovered;
      return const AppPersistenceFailure();
    }
  }

  /// Re-reads household-scoped certificate idempotency after a write failure.
  ///
  /// Equivalent concurrent create must return [AppOk] (not lock noise) once the
  /// winner commits. Conflicting payload → [AppDuplicateConflict].
  /// Retries briefly so a loser that timed out on BEGIN IMMEDIATE can observe
  /// the winner after commit.
  Future<AppResult<SavingsCertificate>?> _resolveCertificateIdempotency({
    required String householdId,
    required String idempotencyKey,
    required String incomingPayload,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final existing = await _db
            .customSelect(
              'SELECT id, idempotency_payload FROM savings_certificates '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(householdId),
                Variable.withString(idempotencyKey),
              ],
            )
            .get();
        if (existing.isNotEmpty) {
          final row = existing.first;
          final stored = row.read<String>('idempotency_payload');
          final decision = decideStringFingerprint(
            incoming: incomingPayload,
            stored: stored,
          );
          if (decision == ScopedIdempotencyDecision.replay) {
            final found = await _findById(row.read<String>('id'));
            return found != null ? AppOk(found) : const AppPersistenceFailure();
          }
          return const AppDuplicateConflict(
            messageKey: 'errorCertificateIdempotencyConflict',
          );
        }
      } catch (_) {
        // Retry below.
      }
      await Future<void>.delayed(Duration(milliseconds: 25 * (attempt + 1)));
    }
    return null;
  }

  /// Re-reads event idempotency after lock contention / UNIQUE race.
  Future<AppResult<T>?> _resolveEventIdempotency<T>({
    required String householdId,
    required String idempotencyKey,
    required String fingerprint,
    required Future<AppResult<T>> Function(QueryRow row) onMatch,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final existing = await _db
            .customSelect(
              'SELECT * FROM certificate_events '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(householdId),
                Variable.withString(idempotencyKey),
              ],
            )
            .get();
        if (existing.isNotEmpty) {
          final row = existing.first;
          if (row.readNullable<String>('payload_fingerprint') == fingerprint) {
            return onMatch(row);
          }
          return AppDuplicateConflict<T>(
            messageKey: 'errorCertificateIdempotencyConflict',
          );
        }
      } catch (_) {
        // Retry below.
      }
      await Future<void>.delayed(Duration(milliseconds: 25 * (attempt + 1)));
    }
    return null;
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsCertificate?>> findById(String certificateId) async {
    try {
      return AppOk(await _findById(certificateId));
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  @override
  Future<AppResult<List<SavingsCertificate>>> listCertificates({
    required String householdId,
    bool includeArchived = false,
  }) async {
    try {
      final rows = await _db
          .customSelect(
            includeArchived
                ? 'SELECT id FROM savings_certificates WHERE household_id = ? '
                      'ORDER BY created_at ASC'
                : "SELECT id FROM savings_certificates WHERE household_id = ? "
                      "AND lifecycle != 'archived' ORDER BY created_at ASC",
            variables: [Variable.withString(householdId)],
          )
          .get();
      final list = <SavingsCertificate>[];
      for (final row in rows) {
        final c = await _findById(row.read<String>('id'));
        if (c != null) list.add(c);
      }
      return AppOk(list);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  @override
  Future<AppResult<int>> getPrincipalBalance({
    required String certificateAccountId,
    required String householdId,
  }) async {
    try {
      final rows = await _db
          .customSelect(
            'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
            'ELSE -amount_minor_units END), 0) AS bal '
            'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
            variables: [
              Variable.withString(LedgerDirection.credit.code),
              Variable.withString(certificateAccountId),
              Variable.withString(householdId),
            ],
          )
          .get();
      return AppOk(rows.first.read<int>('bal'));
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  @override
  Future<AppResult<List<CertificateRevision>>> getRevisions(
    String certificateId,
  ) async {
    try {
      final rows = await _db
          .customSelect(
            'SELECT * FROM certificate_revisions WHERE certificate_id = ? '
            'ORDER BY created_at ASC, id ASC',
            variables: [Variable.withString(certificateId)],
          )
          .get();
      return AppOk(rows.map(_rowToRevision).toList());
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  @override
  Future<AppResult<List<CertificateEvent>>> getEvents(
    String certificateId,
  ) async {
    try {
      final rows = await _db
          .customSelect(
            'SELECT * FROM certificate_events WHERE certificate_id = ? '
            'ORDER BY created_at ASC, id ASC',
            variables: [Variable.withString(certificateId)],
          )
          .get();
      return AppOk(rows.map(_rowToEvent).toList());
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── reviseDefinition ──────────────────────────────────────────────────────

  @override
  Future<AppResult<CertificateRevision>> reviseDefinition({
    required CertificateRevision revision,
  }) async {
    try {
      final cert = await _findById(revision.certificateId);
      if (cert == null) return const AppNotFound();
      if (cert.householdId != revision.householdId) return const AppNotFound();
      if (cert.lifecycle == CertificateLifecycle.archived) {
        return const AppValidationFailure(
          field: 'certificateId',
          messageKey: 'errorCertificateArchived',
        );
      }
      await _insertRevision(revision);
      await _db.customStatement(
        'INSERT INTO certificate_events '
        '(id, certificate_id, household_id, event_type, related_operation_id, '
        'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
        'note, effective_at, created_at, schema_version) '
        'VALUES (?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, ?, ?, ?, 1)',
        [
          _uuid.v4(),
          revision.certificateId,
          revision.householdId,
          CertificateEventType.definitionRevised.code,
          revision.revisionReason,
          revision.createdAt,
          revision.createdAt,
        ],
      );
      return AppOk(revision);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── recordProfit ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<CertificateProfitReceipt>> recordProfit({
    required String certificateId,
    required String householdId,
    required String operationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? note,
  }) async {
    if (amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }

    final fingerprint =
        'profit|cert=$certificateId|dst=$destinationAccountId|'
        'amt=$amountMinorUnits|cur=$currencyCode';

    Future<AppResult<CertificateProfitReceipt>?> recoverProfit() =>
        _resolveEventIdempotency<CertificateProfitReceipt>(
          householdId: householdId,
          idempotencyKey: idempotencyKey,
          fingerprint: fingerprint,
          onMatch: (row) async {
            final event = _rowToEvent(row);
            return AppOk(
              CertificateProfitReceipt(
                event: event,
                incomeOperationId: event.relatedOperationId ?? operationId,
                destinationAccountId: destinationAccountId,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
              ),
            );
          },
        );

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        late AppResult<CertificateProfitReceipt> result;
        try {
          await _db.transaction(() async {
            // Idempotency on certificate events (after writer lock)
            final existing = await _db
                .customSelect(
                  'SELECT * FROM certificate_events '
                  'WHERE household_id = ? AND idempotency_key = ?',
                  variables: [
                    Variable.withString(householdId),
                    Variable.withString(idempotencyKey),
                  ],
                )
                .get();
            if (existing.isNotEmpty) {
              final row = existing.first;
              if (row.readNullable<String>('payload_fingerprint') ==
                  fingerprint) {
                final event = _rowToEvent(row);
                result = AppOk(
                  CertificateProfitReceipt(
                    event: event,
                    incomeOperationId: event.relatedOperationId ?? operationId,
                    destinationAccountId: destinationAccountId,
                    amountMinorUnits: amountMinorUnits,
                    currencyCode: currencyCode,
                  ),
                );
              } else {
                result = const AppDuplicateConflict(
                  messageKey: 'errorCertificateIdempotencyConflict',
                );
              }
              return;
            }

            await _failAfter(CertificateFailAfter.idempotencyLookup);

            final cert = await _findById(certificateId);
            if (cert == null || cert.householdId != householdId) {
              result = const AppNotFound();
              return;
            }
            if (cert.lifecycle == CertificateLifecycle.archived) {
              result = const AppValidationFailure(
                field: 'certificateId',
                messageKey: 'errorCertificateArchived',
              );
              return;
            }
            if (cert.currencyCode != currencyCode) {
              result = const AppValidationFailure(
                field: 'currencyCode',
                messageKey: 'errorCurrencyMismatch',
              );
              return;
            }

            final dstOk =
                await _validateStandardDestination<CertificateProfitReceipt>(
                  accountId: destinationAccountId,
                  householdId: householdId,
                  currencyCode: currencyCode,
                );
            if (dstOk != null) {
              result = dstOk;
              return;
            }

            final now = DateTime.now().toUtc().toIso8601String();

            await _db.customStatement(
              'INSERT INTO operations '
              '(id, household_id, type, effective_date, recorded_at, '
              'total_amount_minor_units, currency_code, created_by, created_at, '
              'updated_at, description, category_code, destination_account_id, '
              'idempotency_key) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                operationId,
                householdId,
                OperationType.income.code,
                effectiveDate,
                now,
                amountMinorUnits,
                currencyCode,
                createdBy,
                now,
                now,
                note ?? 'Certificate profit',
                'certificate_profit',
                destinationAccountId,
                idempotencyKey,
              ],
            );
            await _failAfter(CertificateFailAfter.operationInsert);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${operationId}_credit',
                operationId,
                householdId,
                destinationAccountId,
                LedgerDirection.credit.code,
                amountMinorUnits,
                currencyCode,
                LedgerEntryType.income.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.firstLedgerEntry);

            await _db.customStatement(
              'INSERT INTO operation_contexts '
              '(operation_id, household_id, is_recurring, category_code, note, created_at) '
              'VALUES (?, ?, 0, ?, ?, ?)',
              [
                operationId,
                householdId,
                'certificate_profit',
                note ?? 'Certificate profit',
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.operationContext);

            final event = CertificateEvent(
              id: eventId,
              certificateId: certificateId,
              householdId: householdId,
              eventType: CertificateEventType.profitReceived,
              relatedOperationId: operationId,
              amountMinorUnits: amountMinorUnits,
              currencyCode: currencyCode,
              idempotencyKey: idempotencyKey,
              payloadFingerprint: fingerprint,
              note: note,
              effectiveAt: now,
              createdAt: now,
            );

            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
              [
                event.id,
                event.certificateId,
                event.householdId,
                event.eventType.code,
                event.relatedOperationId,
                event.amountMinorUnits,
                event.currencyCode,
                event.idempotencyKey,
                event.payloadFingerprint,
                event.note,
                event.effectiveAt,
                event.createdAt,
              ],
            );
            await _failAfter(CertificateFailAfter.eventInsert);
            await _failAfter(CertificateFailAfter.preCommit);

            result = AppOk(
              CertificateProfitReceipt(
                event: event,
                incomeOperationId: operationId,
                destinationAccountId: destinationAccountId,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
              ),
            );
          });
          return result;
        } on CertificateInjectedFailure {
          return const AppPersistenceFailure();
        } catch (e) {
          if (isRetryableSqliteContention(e)) rethrow;
          final recovered = await recoverProfit();
          if (recovered != null) return recovered;
          return const AppPersistenceFailure();
        }
      });
    } on SqliteContentionExhausted {
      final recovered = await recoverProfit();
      if (recovered != null) return recovered;
      return const AppPersistenceFailure();
    }
  }

  // ── redeem ────────────────────────────────────────────────────────────────

  @override
  Future<AppResult<CertificateRedemptionSummary>> redeem({
    required String certificateId,
    required String householdId,
    required String principalOperationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int principalMinorUnits,
    required String effectiveDate,
    required String createdBy,
    required String todayLocal,
    CertificateMaturityProfitParams? maturityProfit,
    String? note,
  }) async {
    final fingerprint =
        'redeem|cert=$certificateId|dst=$destinationAccountId|'
        'prin=$principalMinorUnits|profit=${maturityProfit?.amountMinorUnits ?? 0}';

    Future<AppResult<CertificateRedemptionSummary>?> recoverRedeem() =>
        _resolveEventIdempotency<CertificateRedemptionSummary>(
          householdId: householdId,
          idempotencyKey: idempotencyKey,
          fingerprint: fingerprint,
          onMatch: (row) async {
            final cert = await _findById(certificateId);
            if (cert == null) return const AppPersistenceFailure();
            return AppOk(
              CertificateRedemptionSummary(
                certificate: cert,
                principalMinorUnits:
                    row.readNullable<int>('amount_minor_units') ??
                    principalMinorUnits,
                profitMinorUnits: maturityProfit?.amountMinorUnits ?? 0,
                destinationAccountId: destinationAccountId,
                currencyCode: cert.currencyCode,
                principalOperationId:
                    row.readNullable<String>('related_operation_id') ??
                    principalOperationId,
                profitOperationId: maturityProfit?.operationId,
                event: _rowToEvent(row),
              ),
            );
          },
        );

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        late AppResult<CertificateRedemptionSummary> result;
        try {
          await _db.transaction(() async {
            final existing = await _db
                .customSelect(
                  'SELECT * FROM certificate_events '
                  'WHERE household_id = ? AND idempotency_key = ?',
                  variables: [
                    Variable.withString(householdId),
                    Variable.withString(idempotencyKey),
                  ],
                )
                .get();
            if (existing.isNotEmpty) {
              final row = existing.first;
              if (row.readNullable<String>('payload_fingerprint') ==
                  fingerprint) {
                final cert = await _findById(certificateId);
                if (cert == null) {
                  result = const AppPersistenceFailure();
                  return;
                }
                result = AppOk(
                  CertificateRedemptionSummary(
                    certificate: cert,
                    principalMinorUnits:
                        row.readNullable<int>('amount_minor_units') ??
                        principalMinorUnits,
                    profitMinorUnits: maturityProfit?.amountMinorUnits ?? 0,
                    destinationAccountId: destinationAccountId,
                    currencyCode: cert.currencyCode,
                    principalOperationId:
                        row.readNullable<String>('related_operation_id') ??
                        principalOperationId,
                    profitOperationId: maturityProfit?.operationId,
                    event: _rowToEvent(row),
                  ),
                );
              } else {
                result = const AppDuplicateConflict(
                  messageKey: 'errorCertificateIdempotencyConflict',
                );
              }
              return;
            }

            await _failAfter(CertificateFailAfter.idempotencyLookup);

            final cert = await _findById(certificateId);
            if (cert == null || cert.householdId != householdId) {
              result = const AppNotFound();
              return;
            }
            if (cert.lifecycle != CertificateLifecycle.active) {
              result = const AppValidationFailure(
                field: 'lifecycle',
                messageKey: 'errorCertificateNotActive',
              );
              return;
            }
            if (todayLocal.compareTo(cert.maturityDate) < 0) {
              result = const AppValidationFailure(
                field: 'maturityDate',
                messageKey: 'errorCertificateNotMatured',
              );
              return;
            }

            final dstOk =
                await _validateStandardDestination<
                  CertificateRedemptionSummary
                >(
                  accountId: destinationAccountId,
                  householdId: householdId,
                  currencyCode: cert.currencyCode,
                );
            if (dstOk != null) {
              result = dstOk;
              return;
            }

            final balRows = await _db
                .customSelect(
                  'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
                  'ELSE -amount_minor_units END), 0) AS bal '
                  'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
                  variables: [
                    Variable.withString(LedgerDirection.credit.code),
                    Variable.withString(cert.certificateAccountId),
                    Variable.withString(householdId),
                  ],
                )
                .get();
            final balance = balRows.first.read<int>('bal');

            if (principalMinorUnits <= 0) {
              result = const AppValidationFailure(
                field: 'principal',
                messageKey: 'errorCertificateNoPrincipal',
              );
              return;
            }
            if (principalMinorUnits > balance) {
              throw InsufficientFundsError(
                accountId: cert.certificateAccountId,
                availableMinorUnits: balance,
                requestedMinorUnits: principalMinorUnits,
              );
            }
            if (principalMinorUnits != balance) {
              result = const AppValidationFailure(
                field: 'principal',
                messageKey: 'errorCertificateFullRedemptionOnly',
              );
              return;
            }

            if (maturityProfit != null && maturityProfit.amountMinorUnits < 0) {
              result = const AppValidationFailure(
                field: 'profit',
                messageKey: 'error_amount_must_be_positive',
              );
              return;
            }

            final principal = principalMinorUnits;
            final now = DateTime.now().toUtc().toIso8601String();

            // Principal transfer OUT of certificate account.
            await _db.customStatement(
              'INSERT INTO operations '
              '(id, household_id, type, effective_date, recorded_at, '
              'total_amount_minor_units, currency_code, created_by, created_at, '
              'updated_at, description, source_account_id, destination_account_id, '
              'idempotency_key) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                principalOperationId,
                householdId,
                OperationType.certificateMaturity.code,
                effectiveDate,
                now,
                principal,
                cert.currencyCode,
                createdBy,
                now,
                now,
                note ?? 'Certificate redemption',
                cert.certificateAccountId,
                destinationAccountId,
                idempotencyKey,
              ],
            );
            await _failAfter(CertificateFailAfter.operationInsert);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${principalOperationId}_debit',
                principalOperationId,
                householdId,
                cert.certificateAccountId,
                LedgerDirection.debit.code,
                principal,
                cert.currencyCode,
                LedgerEntryType.transferOut.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.firstLedgerEntry);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${principalOperationId}_credit',
                principalOperationId,
                householdId,
                destinationAccountId,
                LedgerDirection.credit.code,
                principal,
                cert.currencyCode,
                LedgerEntryType.transferIn.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.secondLedgerEntry);

            await _db.customStatement(
              'INSERT INTO operation_contexts '
              '(operation_id, household_id, is_recurring, note, created_at) '
              'VALUES (?, ?, 0, ?, ?)',
              [
                principalOperationId,
                householdId,
                note ?? 'Certificate redemption',
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.operationContext);

            String? profitOpId;
            final profitAmt = maturityProfit?.amountMinorUnits ?? 0;
            if (maturityProfit != null && profitAmt > 0) {
              profitOpId = maturityProfit.operationId;
              final profitDst = maturityProfit.destinationAccountId;
              final pDstOk =
                  await _validateStandardDestination<
                    CertificateRedemptionSummary
                  >(
                    accountId: profitDst,
                    householdId: householdId,
                    currencyCode: cert.currencyCode,
                  );
              if (pDstOk != null) {
                result = pDstOk;
                throw Exception('profit destination invalid');
              }

              await _db.customStatement(
                'INSERT INTO operations '
                '(id, household_id, type, effective_date, recorded_at, '
                'total_amount_minor_units, currency_code, created_by, created_at, '
                'updated_at, description, category_code, destination_account_id, '
                'idempotency_key) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  profitOpId,
                  householdId,
                  OperationType.income.code,
                  maturityProfit.effectiveDate,
                  now,
                  profitAmt,
                  cert.currencyCode,
                  createdBy,
                  now,
                  now,
                  maturityProfit.description,
                  'certificate_profit',
                  profitDst,
                  maturityProfit.idempotencyKey,
                ],
              );
              await _failAfter(CertificateFailAfter.profitOperationInsert);
              await _db.customStatement(
                'INSERT INTO ledger_entries '
                '(id, operation_id, household_id, account_id, direction, '
                'amount_minor_units, currency_code, entry_type, effective_date, '
                'recorded_at, created_by) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  '${profitOpId}_credit',
                  profitOpId,
                  householdId,
                  profitDst,
                  LedgerDirection.credit.code,
                  profitAmt,
                  cert.currencyCode,
                  LedgerEntryType.income.code,
                  maturityProfit.effectiveDate,
                  now,
                  createdBy,
                ],
              );
              await _failAfter(CertificateFailAfter.profitLedgerEntry);
              await _db.customStatement(
                'INSERT INTO operation_contexts '
                '(operation_id, household_id, is_recurring, category_code, note, created_at) '
                'VALUES (?, ?, 0, ?, ?, ?)',
                [
                  profitOpId,
                  householdId,
                  'certificate_profit',
                  maturityProfit.description,
                  now,
                ],
              );
              await _failAfter(CertificateFailAfter.profitContext);
              await _db.customStatement(
                'INSERT INTO certificate_events '
                '(id, certificate_id, household_id, event_type, related_operation_id, '
                'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
                'note, effective_at, created_at, schema_version) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
                [
                  _uuid.v4(),
                  certificateId,
                  householdId,
                  CertificateEventType.profitReceived.code,
                  profitOpId,
                  profitAmt,
                  cert.currencyCode,
                  'redeem-profit-$idempotencyKey',
                  'maturity-profit|$fingerprint',
                  maturityProfit.description,
                  now,
                  now,
                ],
              );
              await _failAfter(CertificateFailAfter.profitEventInsert);
            }

            await _db.customStatement(
              "UPDATE savings_certificates SET lifecycle = 'redeemed', "
              'redeemed_at = ? WHERE id = ? AND household_id = ?',
              [now, certificateId, householdId],
            );
            await _failAfter(CertificateFailAfter.lifecycleUpdate);

            final event = CertificateEvent(
              id: eventId,
              certificateId: certificateId,
              householdId: householdId,
              eventType: CertificateEventType.redeemed,
              relatedOperationId: principalOperationId,
              amountMinorUnits: principal,
              currencyCode: cert.currencyCode,
              idempotencyKey: idempotencyKey,
              payloadFingerprint: fingerprint,
              note: note,
              effectiveAt: now,
              createdAt: now,
            );

            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
              [
                event.id,
                event.certificateId,
                event.householdId,
                event.eventType.code,
                event.relatedOperationId,
                event.amountMinorUnits,
                event.currencyCode,
                event.idempotencyKey,
                event.payloadFingerprint,
                event.note,
                event.effectiveAt,
                event.createdAt,
              ],
            );
            await _failAfter(CertificateFailAfter.eventInsert);
            await _failAfter(CertificateFailAfter.preCommit);

            final updated = await _findById(certificateId);
            result = AppOk(
              CertificateRedemptionSummary(
                certificate: updated!,
                principalMinorUnits: principal,
                profitMinorUnits: profitAmt > 0 ? profitAmt : 0,
                destinationAccountId: destinationAccountId,
                currencyCode: cert.currencyCode,
                principalOperationId: principalOperationId,
                profitOperationId: profitOpId,
                event: event,
              ),
            );
          });
          return result;
        } on InsufficientFundsError {
          return const AppInsufficientFunds();
        } on CertificateInjectedFailure {
          return const AppPersistenceFailure();
        } catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isRetryableSqliteContention(e)) rethrow;
          final recovered = await recoverRedeem();
          if (recovered != null) return recovered;
          return const AppPersistenceFailure();
        }
      });
    } on SqliteContentionExhausted {
      final recovered = await recoverRedeem();
      if (recovered != null) return recovered;
      return const AppPersistenceFailure();
    }
  }

  // ── archive / restore ─────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> archive({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) async {
    try {
      await _db.transaction(() async {
        final cert = await _findById(certificateId);
        if (cert == null || cert.householdId != householdId) {
          throw Exception('not found');
        }
        if (cert.lifecycle == CertificateLifecycle.archived) return;
        if (cert.lifecycle == CertificateLifecycle.active) {
          final bal = await getPrincipalBalance(
            certificateAccountId: cert.certificateAccountId,
            householdId: householdId,
          );
          if (bal is AppOk<int> && bal.value != 0) {
            throw Exception('nonzero');
          }
        }
        final now = DateTime.now().toUtc().toIso8601String();
        await _db.customStatement(
          "UPDATE savings_certificates SET lifecycle = 'archived', "
          'archived_at = ? WHERE id = ?',
          [now, certificateId],
        );
        await _db.customStatement(
          'INSERT INTO certificate_events '
          '(id, certificate_id, household_id, event_type, related_operation_id, '
          'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
          'note, effective_at, created_at, schema_version) '
          'VALUES (?, ?, ?, ?, NULL, NULL, NULL, ?, NULL, NULL, ?, ?, 1)',
          [
            _uuid.v4(),
            certificateId,
            householdId,
            CertificateEventType.archived.code,
            idempotencyKey,
            now,
            now,
          ],
        );
      });
      return const AppOk(null);
    } on Exception catch (e) {
      if (e.toString().contains('nonzero')) {
        return const AppValidationFailure(
          field: 'principal',
          messageKey: 'errorCertificateArchiveNonzeroBalance',
        );
      }
      return const AppNotFound();
    }
  }

  @override
  Future<AppResult<void>> restore({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  }) async {
    try {
      await _db.transaction(() async {
        final cert = await _findById(certificateId);
        if (cert == null || cert.householdId != householdId) {
          throw Exception('not found');
        }
        if (cert.lifecycle != CertificateLifecycle.archived) {
          throw Exception('not archived');
        }
        final now = DateTime.now().toUtc().toIso8601String();
        // Restore to active if never redeemed; otherwise back to redeemed.
        final target = cert.redeemedAt != null ? 'redeemed' : 'active';
        // Transition trigger only allows archived→active. If redeemed path needed,
        // restore to active only (V1 policy).
        await _db.customStatement(
          "UPDATE savings_certificates SET lifecycle = 'active', "
          'archived_at = NULL WHERE id = ?',
          [certificateId],
        );
        // If previously redeemed, move active→redeemed again.
        if (target == 'redeemed') {
          await _db.customStatement(
            "UPDATE savings_certificates SET lifecycle = 'redeemed' WHERE id = ?",
            [certificateId],
          );
        }
        await _db.customStatement(
          'INSERT INTO certificate_events '
          '(id, certificate_id, household_id, event_type, related_operation_id, '
          'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
          'note, effective_at, created_at, schema_version) '
          'VALUES (?, ?, ?, ?, NULL, NULL, NULL, ?, NULL, NULL, ?, ?, 1)',
          [
            _uuid.v4(),
            certificateId,
            householdId,
            CertificateEventType.restored.code,
            idempotencyKey,
            now,
            now,
          ],
        );
      });
      return const AppOk(null);
    } on Exception catch (e) {
      if (e.toString().contains('not archived')) {
        return const AppValidationFailure(
          field: 'lifecycle',
          messageKey: 'errorCertificateRestoreRequiresArchived',
        );
      }
      return const AppNotFound();
    }
  }

  // ── reversePurchase ───────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> reversePurchase({
    required String certificateId,
    required String householdId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  }) async {
    Future<String?> purchaseOpId() async {
      final purchaseEvents = await _db
          .customSelect(
            "SELECT related_operation_id FROM certificate_events "
            "WHERE certificate_id = ? AND event_type = 'purchased' "
            'ORDER BY created_at ASC LIMIT 1',
            variables: [Variable.withString(certificateId)],
          )
          .get();
      if (purchaseEvents.isEmpty) return null;
      return purchaseEvents.first.readNullable<String>('related_operation_id');
    }

    Future<AppResult<void>?> recoverPurchaseReversal({
      required String fingerprint,
    }) async {
      try {
        final byEvent = await _db
            .customSelect(
              'SELECT payload_fingerprint FROM certificate_events '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(householdId),
                Variable.withString(idempotencyKey),
              ],
            )
            .get();
        if (byEvent.isNotEmpty) {
          if (byEvent.first.readNullable<String>('payload_fingerprint') ==
              fingerprint) {
            return const AppOk(null);
          }
          return const AppDuplicateConflict(
            messageKey: 'errorCertificateIdempotencyConflict',
          );
        }

        final purchaseOpIdValue = await purchaseOpId();
        if (purchaseOpIdValue != null) {
          final ops = await _db
              .customSelect(
                'SELECT is_reversed FROM operations WHERE id = ?',
                variables: [Variable.withString(purchaseOpIdValue)],
              )
              .get();
          if (ops.isNotEmpty &&
              ops.first.readNullable<int>('is_reversed') == 1) {
            // Same purchase already reversed under a different key → equivalent.
            return const AppOk(null);
          }
        }
      } on Exception {
        // fall through
      }
      return null;
    }

    // Provisional fingerprint before lock (amount/accounts filled inside txn).
    // Recovery after UNIQUE uses the in-txn fingerprint; this provisional is
    // only used when we already know purchase accounts from a prior read.
    String? lastFingerprint;

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        try {
          late AppResult<void> result;
          await _db.transaction(() async {
            final cert = await _findById(certificateId);
            if (cert == null || cert.householdId != householdId) {
              throw Exception('not found');
            }

            final purchaseEvents = await _db
                .customSelect(
                  "SELECT * FROM certificate_events WHERE certificate_id = ? "
                  "AND event_type = 'purchased' ORDER BY created_at ASC LIMIT 1",
                  variables: [Variable.withString(certificateId)],
                )
                .get();
            if (purchaseEvents.isEmpty) throw Exception('no purchase');
            final purchaseOpId = purchaseEvents.first.readNullable<String>(
              'related_operation_id',
            );
            if (purchaseOpId == null) throw Exception('no purchase op');

            final ops = await _db
                .customSelect(
                  'SELECT * FROM operations WHERE id = ? AND household_id = ?',
                  variables: [
                    Variable.withString(purchaseOpId),
                    Variable.withString(householdId),
                  ],
                )
                .get();
            if (ops.isEmpty) throw Exception('missing op');
            final op = ops.first;
            final amount = op.read<int>('total_amount_minor_units');
            final currency = op.read<String>('currency_code');
            final sourceAccountId = op.read<String>('source_account_id');
            final destAccountId = op.read<String>('destination_account_id');
            final fingerprint = buildPurchaseReversalIdempotencyPayload(
              householdId: householdId,
              certificateId: certificateId,
              originalOperationId: purchaseOpId,
              effectiveDate: effectiveDate,
              amountMinorUnits: amount,
              currencyCode: currency,
              sourceAccountId: sourceAccountId,
              destinationAccountId: destAccountId,
              reason: reason,
              createdBy: createdBy,
            );
            lastFingerprint = fingerprint;

            // Scoped key + fingerprint first (equivalent vs conflicting).
            final byKey = await _db
                .customSelect(
                  'SELECT payload_fingerprint FROM certificate_events '
                  'WHERE household_id = ? AND idempotency_key = ?',
                  variables: [
                    Variable.withString(householdId),
                    Variable.withString(idempotencyKey),
                  ],
                )
                .get();
            if (byKey.isNotEmpty) {
              if (byKey.first.readNullable<String>('payload_fingerprint') ==
                  fingerprint) {
                result = const AppOk(null);
                return;
              }
              result = const AppDuplicateConflict(
                messageKey: 'errorCertificateIdempotencyConflict',
              );
              return;
            }

            // Already-reversed purchase (possibly under another key) → AppOk.
            if (op.readNullable<int>('is_reversed') == 1) {
              result = const AppOk(null);
              return;
            }

            if (cert.lifecycle != CertificateLifecycle.active) {
              throw Exception('not active');
            }

            // Reject if later profit or redemption events exist.
            final later = await _db
                .customSelect(
                  "SELECT id FROM certificate_events WHERE certificate_id = ? "
                  "AND event_type IN ('profitReceived','redeemed') LIMIT 1",
                  variables: [Variable.withString(certificateId)],
                )
                .get();
            if (later.isNotEmpty) {
              throw Exception('has later financial events');
            }

            final now = DateTime.now().toUtc().toIso8601String();

            // Mirror reversal: credit source, debit certificate account.
            await _db.customStatement(
              'INSERT INTO operations '
              '(id, household_id, type, effective_date, recorded_at, '
              'total_amount_minor_units, currency_code, created_by, created_at, '
              'updated_at, description, source_account_id, destination_account_id, '
              'idempotency_key, is_reversed) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)',
              [
                reversalOperationId,
                householdId,
                OperationType.reversal.code,
                effectiveDate,
                now,
                amount,
                currency,
                createdBy,
                now,
                now,
                reason ?? 'Purchase reversal',
                destAccountId,
                sourceAccountId,
                idempotencyKey,
              ],
            );
            await _failAfter(CertificateFailAfter.operationInsert);

            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${reversalOperationId}_debit',
                reversalOperationId,
                householdId,
                destAccountId,
                LedgerDirection.debit.code,
                amount,
                currency,
                LedgerEntryType.reversalDebit.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.firstLedgerEntry);
            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${reversalOperationId}_credit',
                reversalOperationId,
                householdId,
                sourceAccountId,
                LedgerDirection.credit.code,
                amount,
                currency,
                LedgerEntryType.reversalCredit.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.secondLedgerEntry);
            await _db.customStatement(
              'INSERT INTO operation_contexts '
              '(operation_id, household_id, is_recurring, note, created_at) '
              'VALUES (?, ?, 0, ?, ?)',
              [
                reversalOperationId,
                householdId,
                reason ?? 'Purchase reversal',
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.operationContext);

            await _db.customStatement(
              'UPDATE operations SET is_reversed = 1, reversed_by = ?, updated_at = ? '
              'WHERE id = ?',
              [reversalOperationId, now, purchaseOpId],
            );

            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
              [
                _uuid.v4(),
                certificateId,
                householdId,
                CertificateEventType.purchaseReversed.code,
                reversalOperationId,
                amount,
                currency,
                idempotencyKey,
                fingerprint,
                reason,
                now,
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.eventInsert);

            // Archive after cancel.
            await _db.customStatement(
              "UPDATE savings_certificates SET lifecycle = 'archived', "
              'archived_at = ? WHERE id = ?',
              [now, certificateId],
            );
            await _failAfter(CertificateFailAfter.lifecycleUpdate);
            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, ?, ?, ?, 1)',
              [
                _uuid.v4(),
                certificateId,
                householdId,
                CertificateEventType.archived.code,
                'after purchase reversal',
                now,
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.preCommit);
            result = const AppOk(null);
          });
          return result;
        } on CertificateInjectedFailure {
          return const AppPersistenceFailure();
        } on Exception catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isRetryableSqliteContention(e)) rethrow;
          final msg = e.toString();
          final fp = lastFingerprint;
          if (fp != null) {
            final recovered = await recoverPurchaseReversal(fingerprint: fp);
            if (recovered != null) return recovered;
          }
          if (msg.contains('has later')) {
            return const AppValidationFailure(
              field: 'certificateId',
              messageKey: 'errorCertificateReversalNotAllowedAfterHistory',
            );
          }
          if (msg.contains('not active')) {
            return const AppValidationFailure(
              field: 'lifecycle',
              messageKey: 'errorCertificateReversalRequiresActive',
            );
          }
          if (msg.contains('UNIQUE') || msg.contains('unique')) {
            // Prefer equivalent recovery; only conflict when fingerprint differs.
            if (fp != null) {
              final recovered = await recoverPurchaseReversal(fingerprint: fp);
              if (recovered != null) return recovered;
            }
            return const AppDuplicateConflict(
              messageKey: 'errorCertificateIdempotencyConflict',
            );
          }
          return const AppNotFound();
        }
      });
    } on SqliteContentionExhausted {
      final fp = lastFingerprint;
      if (fp != null) {
        final recovered = await recoverPurchaseReversal(fingerprint: fp);
        if (recovered != null) return recovered;
      }
      return const AppPersistenceFailure();
    }
  }

  // ── reverseProfit ─────────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> reverseProfit({
    required String certificateId,
    required String householdId,
    required String originalIncomeOperationId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  }) async {
    String? lastFingerprint;

    Future<AppResult<void>?> recoverProfitReversal({
      required String fingerprint,
    }) async {
      try {
        final byEvent = await _db
            .customSelect(
              'SELECT payload_fingerprint FROM certificate_events '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(householdId),
                Variable.withString(idempotencyKey),
              ],
            )
            .get();
        if (byEvent.isNotEmpty) {
          if (byEvent.first.readNullable<String>('payload_fingerprint') ==
              fingerprint) {
            return const AppOk(null);
          }
          return const AppDuplicateConflict(
            messageKey: 'errorCertificateIdempotencyConflict',
          );
        }

        final ops = await _db
            .customSelect(
              'SELECT is_reversed FROM operations WHERE id = ? AND household_id = ?',
              variables: [
                Variable.withString(originalIncomeOperationId),
                Variable.withString(householdId),
              ],
            )
            .get();
        if (ops.isNotEmpty && ops.first.readNullable<int>('is_reversed') == 1) {
          return const AppOk(null);
        }
      } on Exception {
        // fall through
      }
      return null;
    }

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        try {
          late AppResult<void> result;
          await _db.transaction(() async {
            final cert = await _findById(certificateId);
            if (cert == null || cert.householdId != householdId) {
              throw Exception('not found');
            }

            final ops = await _db
                .customSelect(
                  'SELECT * FROM operations WHERE id = ? AND household_id = ?',
                  variables: [
                    Variable.withString(originalIncomeOperationId),
                    Variable.withString(householdId),
                  ],
                )
                .get();
            if (ops.isEmpty) throw Exception('missing op');
            final op = ops.first;
            if (op.read<String>('type') != 'income' ||
                op.readNullable<String>('category_code') !=
                    'certificate_profit') {
              throw Exception('not profit');
            }

            final amount = op.read<int>('total_amount_minor_units');
            final currency = op.read<String>('currency_code');
            final dest = op.readNullable<String>('destination_account_id');
            if (dest == null) throw Exception('no dest');

            final fingerprint = buildProfitReversalIdempotencyPayload(
              householdId: householdId,
              certificateId: certificateId,
              originalIncomeOperationId: originalIncomeOperationId,
              effectiveDate: effectiveDate,
              amountMinorUnits: amount,
              currencyCode: currency,
              destinationAccountId: dest,
              reason: reason,
              createdBy: createdBy,
            );
            lastFingerprint = fingerprint;

            final byKey = await _db
                .customSelect(
                  'SELECT payload_fingerprint FROM certificate_events '
                  'WHERE household_id = ? AND idempotency_key = ?',
                  variables: [
                    Variable.withString(householdId),
                    Variable.withString(idempotencyKey),
                  ],
                )
                .get();
            if (byKey.isNotEmpty) {
              if (byKey.first.readNullable<String>('payload_fingerprint') ==
                  fingerprint) {
                result = const AppOk(null);
                return;
              }
              result = const AppDuplicateConflict(
                messageKey: 'errorCertificateIdempotencyConflict',
              );
              return;
            }

            if (op.readNullable<int>('is_reversed') == 1) {
              result = const AppOk(null);
              return;
            }

            final now = DateTime.now().toUtc().toIso8601String();

            await _db.customStatement(
              'INSERT INTO operations '
              '(id, household_id, type, effective_date, recorded_at, '
              'total_amount_minor_units, currency_code, created_by, created_at, '
              'updated_at, description, source_account_id, '
              'idempotency_key, is_reversed) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)',
              [
                reversalOperationId,
                householdId,
                OperationType.reversal.code,
                effectiveDate,
                now,
                amount,
                currency,
                createdBy,
                now,
                now,
                reason ?? 'Profit reversal',
                dest,
                idempotencyKey,
              ],
            );
            await _failAfter(CertificateFailAfter.operationInsert);
            await _db.customStatement(
              'INSERT INTO ledger_entries '
              '(id, operation_id, household_id, account_id, direction, '
              'amount_minor_units, currency_code, entry_type, effective_date, '
              'recorded_at, created_by) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                '${reversalOperationId}_debit',
                reversalOperationId,
                householdId,
                dest,
                LedgerDirection.debit.code,
                amount,
                currency,
                LedgerEntryType.reversalDebit.code,
                effectiveDate,
                now,
                createdBy,
              ],
            );
            await _failAfter(CertificateFailAfter.firstLedgerEntry);
            await _db.customStatement(
              'INSERT INTO operation_contexts '
              '(operation_id, household_id, is_recurring, note, created_at) '
              'VALUES (?, ?, 0, ?, ?)',
              [
                reversalOperationId,
                householdId,
                reason ?? 'Profit reversal',
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.operationContext);
            await _db.customStatement(
              'UPDATE operations SET is_reversed = 1, reversed_by = ?, updated_at = ? '
              'WHERE id = ?',
              [reversalOperationId, now, originalIncomeOperationId],
            );
            await _db.customStatement(
              'INSERT INTO certificate_events '
              '(id, certificate_id, household_id, event_type, related_operation_id, '
              'amount_minor_units, currency_code, idempotency_key, payload_fingerprint, '
              'note, effective_at, created_at, schema_version) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
              [
                _uuid.v4(),
                certificateId,
                householdId,
                CertificateEventType.profitReversed.code,
                reversalOperationId,
                amount,
                currency,
                idempotencyKey,
                fingerprint,
                reason,
                now,
                now,
              ],
            );
            await _failAfter(CertificateFailAfter.eventInsert);
            await _failAfter(CertificateFailAfter.preCommit);
            result = const AppOk(null);
          });
          return result;
        } on CertificateInjectedFailure {
          return const AppPersistenceFailure();
        } on Exception catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isRetryableSqliteContention(e)) rethrow;
          final fp = lastFingerprint;
          if (fp != null) {
            final recovered = await recoverProfitReversal(fingerprint: fp);
            if (recovered != null) return recovered;
          }
          if (e.toString().contains('UNIQUE') ||
              e.toString().contains('unique')) {
            if (fp != null) {
              final recovered = await recoverProfitReversal(fingerprint: fp);
              if (recovered != null) return recovered;
            }
            return const AppDuplicateConflict(
              messageKey: 'errorCertificateIdempotencyConflict',
            );
          }
          return const AppNotFound();
        }
      });
    } on SqliteContentionExhausted {
      final fp = lastFingerprint;
      if (fp != null) {
        final recovered = await recoverProfitReversal(fingerprint: fp);
        if (recovered != null) return recovered;
      }
      return const AppPersistenceFailure();
    }
  }

  @override
  Future<AppResult<void>> reverseRedemption({
    required String certificateId,
    required String householdId,
  }) async {
    return const AppValidationFailure(
      field: 'redemption',
      messageKey: 'errorCertificateRedemptionReversalNotSupported',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _insertRevision(CertificateRevision r) async {
    await _db
        .into(_db.certificateRevisionsTable)
        .insert(
          CertificateRevisionsTableCompanion.insert(
            id: r.id,
            certificateId: r.certificateId,
            householdId: r.householdId,
            institutionName: r.institutionName,
            reference: Value(r.reference),
            note: Value(r.note),
            annualRateBps: Value(r.annualRateBps),
            profitFrequencyCode: Value(r.profitFrequency?.code),
            createdAt: r.createdAt,
            revisionReason: r.revisionReason,
          ),
        );
  }

  Future<AppResult<T>?> _validateStandardDestination<T>({
    required String accountId,
    required String householdId,
    required String currencyCode,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT id, currency_code, is_archived, type, is_protected '
          'FROM financial_accounts WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(accountId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (rows.isEmpty) return const AppNotFound();
    final a = rows.first;
    if (a.read<int>('is_archived') == 1) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    final type = a.read<String>('type');
    if (type == 'goalReserve' || type == 'certificate') {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorCertificateAccountNotAllowedAsDestination',
      );
    }
    if (a.read<String>('currency_code') != currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }
    return null;
  }

  Future<SavingsCertificate?> _findById(String id) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM savings_certificates WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    final g = rows.first;
    final revRows = await _db
        .customSelect(
          'SELECT * FROM certificate_revisions WHERE certificate_id = ? '
          'ORDER BY created_at DESC, id DESC LIMIT 1',
          variables: [Variable.withString(id)],
        )
        .get();
    if (revRows.isEmpty) return null;
    final rev = _rowToRevision(revRows.first);
    return SavingsCertificate(
      id: g.read<String>('id'),
      householdId: g.read<String>('household_id'),
      certificateAccountId: g.read<String>('certificate_account_id'),
      currencyCode: g.read<String>('currency_code'),
      originalPrincipalMinorUnits: g.read<int>(
        'original_principal_minor_units',
      ),
      startDate: g.read<String>('start_date'),
      maturityDate: g.read<String>('maturity_date'),
      lifecycle: _lifecycleFromCode(g.read<String>('lifecycle')),
      currentRevision: rev,
      createdAt: g.read<String>('created_at'),
      idempotencyKey: g.read<String>('idempotency_key'),
      schemaVersion: g.read<int>('schema_version'),
      redeemedAt: g.readNullable<String>('redeemed_at'),
      archivedAt: g.readNullable<String>('archived_at'),
    );
  }

  CertificateRevision _rowToRevision(QueryRow rev) => CertificateRevision(
    id: rev.read<String>('id'),
    certificateId: rev.read<String>('certificate_id'),
    householdId: rev.read<String>('household_id'),
    institutionName: rev.read<String>('institution_name'),
    reference: rev.readNullable<String>('reference'),
    note: rev.readNullable<String>('note'),
    annualRateBps: rev.readNullable<int>('annual_rate_bps'),
    profitFrequency: CertificateProfitFrequency.fromCode(
      rev.readNullable<String>('profit_frequency_code'),
    ),
    createdAt: rev.read<String>('created_at'),
    revisionReason: rev.read<String>('revision_reason'),
  );

  CertificateEvent _rowToEvent(QueryRow e) => CertificateEvent(
    id: e.read<String>('id'),
    certificateId: e.read<String>('certificate_id'),
    householdId: e.read<String>('household_id'),
    eventType: CertificateEventType.fromCode(e.read<String>('event_type')),
    relatedOperationId: e.readNullable<String>('related_operation_id'),
    amountMinorUnits: e.readNullable<int>('amount_minor_units'),
    currencyCode: e.readNullable<String>('currency_code'),
    idempotencyKey: e.readNullable<String>('idempotency_key'),
    payloadFingerprint: e.readNullable<String>('payload_fingerprint'),
    note: e.readNullable<String>('note'),
    effectiveAt: e.read<String>('effective_at'),
    createdAt: e.read<String>('created_at'),
  );

  CertificateLifecycle _lifecycleFromCode(String code) => switch (code) {
    'redeemed' => CertificateLifecycle.redeemed,
    'archived' => CertificateLifecycle.archived,
    _ => CertificateLifecycle.active,
  };
}
