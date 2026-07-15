import 'package:family_money_manager/core/logging/log_level.dart';
import 'package:family_money_manager/core/logging/redacted_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late TestLogSink sink;
  late RedactedLogger logger;

  setUp(() {
    sink = TestLogSink();
    logger = RedactedLogger('test', sink: sink);
  });

  group('RedactedLogger — allowlisting', () {
    test('logOperation emits a record', () {
      logger.logOperation(operationType: 'transfer', operationId: 'op-123');
      expect(sink.records, hasLength(1));
    });

    test('logOperation output contains operationType', () {
      logger.logOperation(operationType: 'transfer', operationId: 'op-123');
      expect(sink.lastMessage, contains('transfer'));
    });

    test('logOperation output contains operationId', () {
      logger.logOperation(operationType: 'income', operationId: 'op-abc');
      expect(sink.lastMessage, contains('op-abc'));
    });

    test('logOperation emits at INFO level', () {
      logger.logOperation(operationType: 'expense', operationId: 'op-xyz');
      expect(sink.records.last.level, LogLevel.info);
    });

    test('logNavigation emits a record at DEBUG level', () {
      logger.logNavigation('/smoke');
      expect(sink.records.last.level, LogLevel.debug);
      expect(sink.lastMessage, contains('/smoke'));
    });

    test('warning emits at WARNING level', () {
      logger.warning('sync queue is empty');
      expect(sink.records.last.level, LogLevel.warning);
    });

    test('error emits at ERROR level', () {
      logger.error('STORAGE_FAILURE');
      expect(sink.records.last.level, LogLevel.error);
    });
  });

  group('RedactedLogger — sensitive-pattern masking', () {
    test('EGP amount in warning message is masked', () {
      logger.warning('processing 1500 EGP payment');
      expect(sink.lastMessage, isNot(contains('1500 EGP')));
      expect(sink.lastMessage, contains('[AMOUNT_REDACTED]'));
    });

    test('EGP with comma-separated digits is masked', () {
      logger.warning('total is 12,000 EGP');
      expect(sink.lastMessage, isNot(contains('12,000 EGP')));
      expect(sink.lastMessage, contains('[AMOUNT_REDACTED]'));
    });

    test('EGP amount with currency prefix is masked', () {
      logger.warning('refund of EGP 350 processed');
      expect(sink.lastMessage, isNot(contains('EGP 350')));
      expect(sink.lastMessage, contains('[AMOUNT_REDACTED]'));
    });

    test('Bearer token in warning message is masked', () {
      logger.warning('auth header: Bearer eyJhbGciOiJSUzI1NiJ9.payload.sig');
      expect(sink.lastMessage, isNot(contains('eyJhbGciOiJSUzI1NiJ9')));
      expect(sink.lastMessage, contains('[TOKEN_REDACTED]'));
    });

    test('balance keyword with number is masked', () {
      logger.warning('account balance: 99000 exceeded limit');
      expect(sink.lastMessage, isNot(contains('99000')));
      expect(sink.lastMessage, contains('[BALANCE_REDACTED]'));
    });

    test('message without sensitive patterns is passed through unchanged', () {
      logger.warning('sync started successfully');
      expect(sink.lastMessage, 'sync started successfully');
    });
  });

  group('RedactedLogger — log injection prevention', () {
    test('newline characters in operationType are replaced', () {
      logger.logOperation(
        operationType: 'transfer\ninjection',
        operationId: 'id-1',
      );
      expect(sink.lastMessage, isNot(contains('\n')));
    });

    test('newline characters in operationId are replaced', () {
      logger.logOperation(
        operationType: 'expense',
        operationId: 'id\r\ninjection',
      );
      expect(sink.lastMessage, isNot(contains('\r\n')));
    });
  });
}
