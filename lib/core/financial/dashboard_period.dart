library;

/// A bounded time period for financial summary queries.
///
/// TIMEZONE POLICY (V1):
/// All effective dates are stored as 'YYYY-MM-DD' strings without timezone
/// offset. The application currently has no household-specific timezone. All
/// period calculations use the device's local timezone for UI display, but
/// the persisted effectiveDate string is compared lexicographically in SQL.
/// Household-specific timezone selection is deferred.
///
/// BACKDATING POLICY:
/// Period inclusion is determined by effectiveDate (user-chosen date),
/// NOT by recordedAt (system UTC timestamp).
///
/// REVERSAL POLICY:
/// A reversal's effectiveDate determines which period it affects.
/// A fully reversed expense: original in period T, reversal in period T
/// → net contribution to period T is zero.
/// A reversal in period T+1 for an operation in period T:
/// → original contributes to T, reversal contributes to T+1.
///
/// CLOCK INJECTION:
/// Domain and query logic must never call DateTime.now() directly.
/// A [Clock] abstraction is injected to allow deterministic testing.

import 'package:meta/meta.dart';

/// Opaque clock abstraction. Injected by providers; faked in tests.
abstract interface class Clock {
  DateTime get now;
}

/// Production clock using DateTime.now() in local timezone.
final class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime get now => DateTime.now();
}

/// A closed-open time period [start, end).
///
/// - Start date is inclusive (effectiveDate >= startDate)
/// - End date is exclusive (effectiveDate < endDate)
/// - Dates are 'YYYY-MM-DD' strings for direct SQL comparison
@immutable
final class DashboardPeriod {
  const DashboardPeriod({required this.startDate, required this.endDate, required this.label});

  /// 'YYYY-MM-DD' inclusive start boundary.
  final String startDate;

  /// 'YYYY-MM-DD' exclusive end boundary.
  final String endDate;

  /// Which named period this represents.
  final DashboardPeriodLabel label;

  /// Current calendar month in local time.
  factory DashboardPeriod.currentMonth(Clock clock) {
    final now = clock.now;
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DashboardPeriod(
      startDate: _fmt(start),
      endDate: _fmt(end),
      label: DashboardPeriodLabel.currentMonth,
    );
  }

  /// Previous calendar month.
  factory DashboardPeriod.previousMonth(Clock clock) {
    final now = clock.now;
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 1);
    return DashboardPeriod(
      startDate: _fmt(start),
      endDate: _fmt(end),
      label: DashboardPeriodLabel.previousMonth,
    );
  }

  /// Current calendar year.
  factory DashboardPeriod.currentYear(Clock clock) {
    final now = clock.now;
    return DashboardPeriod(
      startDate: '${now.year}-01-01',
      endDate: '${now.year + 1}-01-01',
      label: DashboardPeriodLabel.currentYear,
    );
  }

  /// Custom date range (inclusive start, exclusive end).
  factory DashboardPeriod.custom({required String startDate, required String endDate}) {
    return DashboardPeriod(
      startDate: startDate,
      endDate: endDate,
      label: DashboardPeriodLabel.custom,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Returns true when [effectiveDate] falls within this period.
  ///
  /// Uses lexicographic string comparison (YYYY-MM-DD format).
  bool contains(String effectiveDate) =>
      effectiveDate.compareTo(startDate) >= 0 && effectiveDate.compareTo(endDate) < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardPeriod &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.label == label;

  @override
  int get hashCode => Object.hash(startDate, endDate, label);

  @override
  String toString() => 'DashboardPeriod($startDate–$endDate, ${label.name})';
}

/// Named labels for dashboard time periods.
enum DashboardPeriodLabel { currentMonth, previousMonth, currentYear, custom }
