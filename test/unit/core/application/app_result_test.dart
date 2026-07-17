/// Tests for the [AppResult] sealed class hierarchy (Phase 3A.1 §1).
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppOk', () {
    test('holds the success value', () {
      const result = AppOk(42);
      expect(result.value, 42);
    });

    test('is an AppResult', () {
      const AppResult<int> result = AppOk(0);
      expect(result, isA<AppOk<int>>());
    });
  });

  group('AppValidationFailure', () {
    test('exposes field and messageKey', () {
      const result = AppValidationFailure<int>(field: 'name', messageKey: 'error_name_empty');
      expect(result.field, 'name');
      expect(result.messageKey, 'error_name_empty');
    });
  });

  group('AppDuplicateConflict', () {
    test('exposes messageKey', () {
      const result = AppDuplicateConflict<String>(messageKey: 'error_duplicate');
      expect(result.messageKey, 'error_duplicate');
    });
  });

  group('AppNotFound', () {
    test('can be instantiated', () {
      const result = AppNotFound<int>();
      expect(result, isA<AppNotFound<int>>());
    });
  });

  group('AppIsolationViolation', () {
    test('can be instantiated', () {
      const result = AppIsolationViolation<int>();
      expect(result, isA<AppIsolationViolation<int>>());
    });
  });

  group('AppClassificationImmutabilityViolation', () {
    test('exposes field', () {
      const result = AppClassificationImmutabilityViolation<int>(field: 'isProtected');
      expect(result.field, 'isProtected');
    });
  });

  group('AppPersistenceFailure', () {
    test('can be instantiated', () {
      const result = AppPersistenceFailure<int>();
      expect(result, isA<AppPersistenceFailure<int>>());
    });
  });

  group('AppUnexpectedFailure', () {
    test('can be instantiated', () {
      const result = AppUnexpectedFailure<int>();
      expect(result, isA<AppUnexpectedFailure<int>>());
    });
  });

  group('Pattern matching on AppResult variants', () {
    String describe(AppResult<int> r) => switch (r) {
      AppOk(:final value) => 'ok:$value',
      AppValidationFailure(:final field, :final messageKey) => 'validation:$field:$messageKey',
      AppDuplicateConflict(:final messageKey) => 'duplicate:$messageKey',
      AppNotFound() => 'not_found',
      AppIsolationViolation() => 'isolation',
      AppClassificationImmutabilityViolation(:final field) => 'immutability:$field',
      AppPersistenceFailure() => 'persistence',
      AppUnexpectedFailure() => 'unexpected',
      AppInsufficientFunds() => 'insufficient_funds',
    };

    test('AppOk matches correctly', () {
      expect(describe(const AppOk(7)), 'ok:7');
    });

    test('AppValidationFailure matches correctly', () {
      expect(describe(const AppValidationFailure(field: 'f', messageKey: 'k')), 'validation:f:k');
    });

    test('AppDuplicateConflict matches correctly', () {
      expect(describe(const AppDuplicateConflict(messageKey: 'dup')), 'duplicate:dup');
    });

    test('AppNotFound matches correctly', () {
      expect(describe(const AppNotFound()), 'not_found');
    });

    test('AppIsolationViolation matches correctly', () {
      expect(describe(const AppIsolationViolation()), 'isolation');
    });

    test('AppClassificationImmutabilityViolation matches correctly', () {
      expect(describe(const AppClassificationImmutabilityViolation(field: 'x')), 'immutability:x');
    });

    test('AppPersistenceFailure matches correctly', () {
      expect(describe(const AppPersistenceFailure()), 'persistence');
    });

    test('AppUnexpectedFailure matches correctly', () {
      expect(describe(const AppUnexpectedFailure()), 'unexpected');
    });
  });
}
