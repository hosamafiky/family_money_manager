/// DashboardPeriod boundary tests (Phase 4A).
///
/// Tests:
/// 1. currentMonth boundaries contain mid-month date
/// 2. currentMonth boundaries exclude prev-month date
/// 3. previousMonth boundaries correct
/// 4. currentYear boundaries correct
/// 5. custom period contains only its dates
/// 6. DashboardPeriod.contains() correct
library;

import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardPeriod boundaries', () {
    test('1. currentMonth boundaries contain mid-month date', () {
      final clock = _FakeClock(DateTime(2025, 3, 15));
      final period = DashboardPeriod.currentMonth(clock);
      expect(period.startDate, '2025-03-01');
      expect(period.endDate, '2025-04-01');
      expect(period.contains('2025-03-15'), isTrue);
    });

    test('2. currentMonth boundaries exclude prev-month date', () {
      final clock = _FakeClock(DateTime(2025, 3, 15));
      final period = DashboardPeriod.currentMonth(clock);
      // February 28 is before March 1 → excluded
      expect(period.contains('2025-02-28'), isFalse);
      // April 1 is the exclusive end → excluded
      expect(period.contains('2025-04-01'), isFalse);
    });

    test('3. previousMonth boundaries correct', () {
      final clock = _FakeClock(DateTime(2025, 3, 10));
      final period = DashboardPeriod.previousMonth(clock);
      expect(period.startDate, '2025-02-01');
      expect(period.endDate, '2025-03-01');
      expect(period.contains('2025-02-15'), isTrue);
      expect(period.contains('2025-03-01'), isFalse);
    });

    test('3b. previousMonth handles January (rolls back to December)', () {
      final clock = _FakeClock(DateTime(2025, 1, 5));
      final period = DashboardPeriod.previousMonth(clock);
      // DateTime(2025, 0, 1) = December 1, 2024 in Dart
      expect(period.startDate, '2024-12-01');
      expect(period.endDate, '2025-01-01');
      expect(period.contains('2024-12-25'), isTrue);
      expect(period.contains('2025-01-01'), isFalse);
    });

    test('4. currentYear boundaries correct', () {
      final clock = _FakeClock(DateTime(2025, 7, 1));
      final period = DashboardPeriod.currentYear(clock);
      expect(period.startDate, '2025-01-01');
      expect(period.endDate, '2026-01-01');
      expect(period.contains('2025-06-15'), isTrue);
      expect(period.contains('2025-12-31'), isTrue);
      expect(period.contains('2026-01-01'), isFalse);
    });

    test('5. custom period contains only its dates', () {
      final period = DashboardPeriod.custom(startDate: '2025-03-01', endDate: '2025-03-16');
      expect(period.contains('2025-03-01'), isTrue);
      expect(period.contains('2025-03-15'), isTrue);
      expect(period.contains('2025-03-16'), isFalse);
      expect(period.contains('2025-02-28'), isFalse);
    });

    test('6. DashboardPeriod.contains() correct for boundary values', () {
      final period = DashboardPeriod.custom(startDate: '2025-01-01', endDate: '2025-02-01');
      // Inclusive start
      expect(period.contains('2025-01-01'), isTrue);
      // Exclusive end
      expect(period.contains('2025-02-01'), isFalse);
      // Middle
      expect(period.contains('2025-01-15'), isTrue);
      // Before
      expect(period.contains('2024-12-31'), isFalse);
    });
  });
}

class _FakeClock implements Clock {
  const _FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime get now => _now;
}
