/// The one path a user-initiated reversal takes into the ledger.
///
/// The rule under test throughout: a person correcting their own ledger must
/// say why. The repository will reverse without a reason because internal
/// flows need that; this use case is what makes the reason non-optional, and
/// what turns every low-level failure into something a screen can render.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/application/reverse_transaction_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake that records what it was asked to do and can be told to fail.
///
/// Only [reverseOperation] is implemented. Every other member throws through
/// [noSuchMethod], so a use case that reaches for anything else fails loudly
/// instead of silently receiving an empty result.
final class _RecordingLedgerRepository implements LedgerRepository {
  final List<ReverseOperationParams> reversals = [];

  IdempotentOperationResult result = IdempotentOperationResult.created;
  Object? throwOnReverse;

  @override
  Future<IdempotentOperationResult> reverseOperation(
    ReverseOperationParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    if (throwOnReverse case final Object error) throw error;
    reversals.add(params);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'ReverseTransactionUseCase must not call '
    '${invocation.memberName} on the ledger repository.',
  );
}

void main() {
  late _RecordingLedgerRepository ledger;
  late ReverseTransactionUseCase useCase;

  setUp(() {
    ledger = _RecordingLedgerRepository();
    useCase = ReverseTransactionUseCase(ledgerRepository: ledger);
  });

  Future<AppResult<String>> reverse({
    String reason = 'Entered twice by mistake',
    String effectiveDate = '2026-07-25',
    String householdId = 'household-v1',
  }) => useCase.execute(
    reversalOperationId: 'rev-1',
    originalOperationId: 'op-1',
    householdId: householdId,
    effectiveDate: effectiveDate,
    createdBy: 'member-1',
    reason: reason,
  );

  group('the reason is required', () {
    test('an empty reason is rejected before the ledger is touched', () async {
      final result = await reverse(reason: '');

      expect(result, isA<AppValidationFailure<String>>());
      expect(
        (result as AppValidationFailure<String>).messageKey,
        'errorReversalReasonRequired',
      );
      expect(ledger.reversals, isEmpty);
    });

    test('a whitespace-only reason is empty, not a reason', () async {
      final result = await reverse(reason: '   \n  ');

      expect(result, isA<AppValidationFailure<String>>());
      expect(ledger.reversals, isEmpty);
    });

    test('a reason past the length limit is rejected', () async {
      final result = await reverse(reason: 'x' * (maxReversalReasonLength + 1));

      expect(
        (result as AppValidationFailure<String>).messageKey,
        'errorReversalReasonTooLong',
      );
      expect(ledger.reversals, isEmpty);
    });

    test('the reason reaches the ledger trimmed', () async {
      await reverse(reason: '  Wrong account  ');

      expect(ledger.reversals.single.reason, 'Wrong account');
    });
  });

  group('validation of the rest of the request', () {
    test('a malformed effective date is rejected', () async {
      final result = await reverse(effectiveDate: '25/07/2026');

      expect((result as AppValidationFailure<String>).field, 'effectiveDate');
      expect(ledger.reversals, isEmpty);
    });

    test('an empty household is rejected', () async {
      final result = await reverse(householdId: '');

      expect((result as AppValidationFailure<String>).field, 'householdId');
      expect(ledger.reversals, isEmpty);
    });
  });

  group('outcomes', () {
    test('a recorded reversal returns its own operation id', () async {
      final result = await reverse();

      expect(result, isA<AppOk<String>>());
      expect((result as AppOk<String>).value, 'rev-1');
      expect(ledger.reversals.single.originalOperationId, 'op-1');
    });

    test(
      'a repeated confirm of the same reversal succeeds rather than '
      'conflicting — the counter-entry it names is already in the ledger',
      () async {
        ledger.result = IdempotentOperationResult.alreadyExists;

        final result = await reverse();

        expect(result, isA<AppOk<String>>());
      },
    );

    test('an id collision with a different operation is a conflict', () async {
      ledger.result = IdempotentOperationResult.conflict;

      final result = await reverse();

      expect(
        (result as AppDuplicateConflict<String>).messageKey,
        'errorReversalConflict',
      );
    });

    test('a missing original is not found', () async {
      ledger.throwOnReverse = OperationNotFoundError('op-1');

      expect(await reverse(), isA<AppNotFound<String>>());
    });

    test('an already-reversed original says so specifically', () async {
      ledger.throwOnReverse = DuplicateReversalError('op-1');

      final result = await reverse();

      expect(
        (result as AppDuplicateConflict<String>).messageKey,
        'errorOperationAlreadyReversed',
      );
    });

    test('a reversal that would debit protected money is surfaced', () async {
      ledger.throwOnReverse = MissingProtectedWithdrawalAuditError('acct-1');

      final result = await reverse();

      expect(
        (result as AppValidationFailure<String>).messageKey,
        'errorReversalRequiresProtectedAudit',
      );
    });

    test(
      'a counter-entry that would overdraft is insufficient funds',
      () async {
        ledger.throwOnReverse = InsufficientFundsError(
          accountId: 'acct-1',
          availableMinorUnits: 0,
          requestedMinorUnits: 38250,
        );

        expect(await reverse(), isA<AppInsufficientFunds<String>>());
      },
    );

    test('an unexpected failure never escapes as a raw exception', () async {
      ledger.throwOnReverse = StateError('boom');

      expect(await reverse(), isA<AppPersistenceFailure<String>>());
    });
  });
}
