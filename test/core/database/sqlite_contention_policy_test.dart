/// Phase 6A.3 — Shared SQLite contention policy unit tests.
library;

import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart' show SqliteException;

void main() {
  group('SqliteContentionCodes / detection', () {
    test('POL-1. SQLITE_BUSY (5) is retryable', () {
      final e = SqliteException(
        extendedResultCode: SqliteContentionCodes.busy,
        message: 'database is locked',
      );
      expect(isRetryableSqliteContention(e), isTrue);
      expect(sqlitePrimaryResultCode(e), SqliteContentionCodes.busy);
    });

    test('POL-2. SQLITE_LOCKED (6) is retryable', () {
      final e = SqliteException(
        extendedResultCode: SqliteContentionCodes.locked,
        message: 'database table is locked',
      );
      expect(isRetryableSqliteContention(e), isTrue);
    });

    test('POL-3. SQLITE_CONSTRAINT (19) is not retryable', () {
      final e = SqliteException(
        extendedResultCode: 19,
        message: 'UNIQUE constraint failed',
      );
      expect(isRetryableSqliteContention(e), isFalse);
    });

    test(
      'POL-4. Negative-balance trigger abort is not retryable contention',
      () {
        final e = SqliteException(
          extendedResultCode: 19,
          message: 'account balance cannot go negative',
        );
        expect(isRetryableSqliteContention(e), isFalse);
        expect(isNegativeBalanceAbort(e), isTrue);
      },
    );
  });

  group('runAuthoritativeWriteWithContentionRetry', () {
    test('POL-5. Succeeds without retry on first attempt', () async {
      var calls = 0;
      final value = await runAuthoritativeWriteWithContentionRetry(() async {
        calls++;
        return 42;
      });
      expect(value, 42);
      expect(calls, 1);
    });

    test(
      'POL-6. Retries BUSY then succeeds; new action each attempt',
      () async {
        var calls = 0;
        final value = await runAuthoritativeWriteWithContentionRetry(
          () async {
            calls++;
            if (calls < 3) {
              throw SqliteException(
                extendedResultCode: SqliteContentionCodes.busy,
                message: 'database is locked',
              );
            }
            return 'ok';
          },
          maxAttempts: 5,
          baseBackoff: const Duration(milliseconds: 1),
          maxBackoff: const Duration(milliseconds: 2),
        );
        expect(value, 'ok');
        expect(calls, 3);
      },
    );

    test('POL-7. Non-retryable errors are not retried', () async {
      var calls = 0;
      await expectLater(
        () => runAuthoritativeWriteWithContentionRetry(() async {
          calls++;
          throw SqliteException(
            extendedResultCode: 19,
            message: 'UNIQUE constraint failed',
          );
        }),
        throwsA(isA<SqliteException>()),
      );
      expect(calls, 1);
    });

    test(
      'POL-8. Exhaustion throws SqliteContentionExhausted (not raw SQLite)',
      () async {
        await expectLater(
          () => runAuthoritativeWriteWithContentionRetry(
            () async {
              throw SqliteException(
                extendedResultCode: SqliteContentionCodes.busy,
                message: 'database is locked',
              );
            },
            maxAttempts: 3,
            baseBackoff: const Duration(milliseconds: 1),
            maxBackoff: const Duration(milliseconds: 1),
          ),
          throwsA(isA<SqliteContentionExhausted>()),
        );
      },
    );
  });
}
