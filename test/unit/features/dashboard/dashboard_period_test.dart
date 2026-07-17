/// Unit tests for DashboardPeriod (Phase 4A).
///
/// Tests:
/// 1. currentMonth builds correct date strings
/// 2. previousMonth handles January (rolls back to December)
/// 3. currentYear builds correct range
/// 4. contains() correctly includes/excludes boundary dates
/// 5. custom period respects provided dates
/// 6. SystemClock returns current time (smoke test)
library;

import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements Clock {
  const _FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime get now => _now;
}

void main() {
  group('DashboardPeriod', () {
    test('1. currentMonth builds correct date strings', () {
      final clock = _FakeClock(DateTime(2025, 6, 20));
      final period = DashboardPeriod.currentMonth(clock);
      expect(period.startDate, '2025-06-01');
      expect(period.endDate, '2025-07-01');
      expect(period.label, DashboardPeriodLabel.currentMonth);
    });

    test('2. previousMonth handles January (rolls back to December)', () {
      final clock = _FakeClock(DateTime(2025, 1, 10));
      final period = DashboardPeriod.previousMonth(clock);
      expect(period.startDate, '2024-12-01');
      expect(period.endDate, '2025-01-01');
      expect(period.label, DashboardPeriodLabel.previousMonth);
    });

    test('3. currentYear builds correct range', () {
      final clock = _FakeClock(DateTime(2025, 8, 1));
      final period = DashboardPeriod.currentYear(clock);
      expect(period.startDate, '2025-01-01');
      expect(period.endDate, '2026-01-01');
      expect(period.label, DashboardPeriodLabel.currentYear);
    });

    test('4. contains() correctly includes/excludes boundary dates', () {
      final period = DashboardPeriod.custom(startDate: '2025-03-01', endDate: '2025-04-01');
      expect(period.contains('2025-03-01'), isTrue);
      expect(period.contains('2025-03-31'), isTrue);
      expect(period.contains('2025-04-01'), isFalse);
      expect(period.contains('2025-02-28'), isFalse);
    });

    test('5. custom period respects provided dates', () {
      final period = DashboardPeriod.custom(startDate: '2024-06-15', endDate: '2024-07-15');
      expect(period.startDate, '2024-06-15');
      expect(period.endDate, '2024-07-15');
      expect(period.label, DashboardPeriodLabel.custom);
      expect(period.contains('2024-06-15'), isTrue);
      expect(period.contains('2024-07-14'), isTrue);
      expect(period.contains('2024-07-15'), isFalse);
    });

    test('6. SystemClock returns current time (smoke test)', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final clockNow = clock.now;
      final after = DateTime.now();
      // SystemClock.now should be between before and after
      expect(
        clockNow.isAfter(before.subtract(const Duration(seconds: 1))) &&
            clockNow.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
