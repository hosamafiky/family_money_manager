import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture enforcement for Phase 6B.1 boundary rules.
///
/// Static source scans — they do not execute financial writers.
void main() {
  List<File> dartFilesUnder(String relative) {
    final dir = Directory('lib/$relative');
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  bool importsPackage(String source, String packagePrefix) {
    return RegExp("import\\s+'package:$packagePrefix").hasMatch(source);
  }

  test('domain layers do not import Flutter, Riverpod, or Drift', () {
    final violations = <String>[];
    for (final file in dartFilesUnder('features')) {
      if (!file.path.contains(
        '${Platform.pathSeparator}domain'
        '${Platform.pathSeparator}',
      )) {
        continue;
      }
      final src = file.readAsStringSync();
      if (importsPackage(src, 'flutter') ||
          importsPackage(src, 'flutter_riverpod') ||
          importsPackage(src, 'drift') ||
          src.contains('package:family_money_manager/core/database/')) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('core/financial is Flutter/Drift/Riverpod-free', () {
    final violations = <String>[];
    for (final file in dartFilesUnder('core/financial')) {
      final src = file.readAsStringSync();
      if (importsPackage(src, 'flutter') ||
          importsPackage(src, 'flutter_riverpod') ||
          importsPackage(src, 'drift')) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('presentation does not import Drift or reference AppDatabase', () {
    final violations = <String>[];
    for (final file in dartFilesUnder('features')) {
      if (!file.path.contains(
        '${Platform.pathSeparator}presentation'
        '${Platform.pathSeparator}',
      )) {
        continue;
      }
      final src = file.readAsStringSync();
      if (importsPackage(src, 'drift') ||
          RegExp(r'\bAppDatabase\b').hasMatch(src)) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('presentation screens do not construct ledger writes', () {
    final violations = <String>[];
    for (final file in dartFilesUnder('features')) {
      if (!file.path.contains(
        '${Platform.pathSeparator}presentation'
        '${Platform.pathSeparator}',
      )) {
        continue;
      }
      // Provider wiring may construct Drift repositories; screens must not.
      if (file.path.endsWith('_providers.dart')) continue;
      final src = file.readAsStringSync();
      if (src.contains('OperationsCompanion') ||
          src.contains('LedgerEntriesCompanion') ||
          src.contains('customStatement(') ||
          src.contains('DriftLedgerRepository(')) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('features avoid /100 money scaling on amount lines', () {
    final violations = <String>[];
    final pattern = RegExp(r'/ ?100(?:\.0)?\b');
    for (final file in dartFilesUnder('features')) {
      final src = file.readAsStringSync();
      for (final line in src.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (pattern.hasMatch(line) &&
            (line.contains('minor') ||
                line.contains('amount') ||
                line.contains('Money') ||
                line.contains('balance'))) {
          violations.add('${file.path}: $trimmed');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('authoritative debit writers use contention retry helper', () {
    for (final path in [
      'lib/features/ledger/data/drift_ledger_repository.dart',
      'lib/features/goals/data/drift_goal_repository.dart',
      'lib/features/certificates/data/drift_certificate_repository.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(
        src.contains('runAuthoritativeWriteWithContentionRetry'),
        isTrue,
        reason: '$path must use contention retry',
      );
    }
  });

  test('schemaVersion remains 18', () {
    final src = File('lib/core/database/app_database.dart').readAsStringSync();
    expect(src.contains('schemaVersion => 18'), isTrue);
  });

  test('account eligibility policy exists for ordinary endpoints', () {
    final src = File(
      'lib/features/accounts/domain/account_eligibility.dart',
    ).readAsStringSync();
    expect(src.contains('isOrdinaryTransactionEndpoint'), isTrue);
    expect(src.contains('isFeatureManagedType'), isTrue);
  });
}
