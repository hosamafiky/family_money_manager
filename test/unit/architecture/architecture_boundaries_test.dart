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

  test('no feature paints a raw Material palette colour', () {
    // Financial state is carried by semantic roles on AppFinancialColors, and
    // a raw hue bypasses every guarantee those roles make: the income/expense
    // axis stays off the green–red pair both common dichromacies collapse,
    // dark mode gets a value that actually clears AA, and there is exactly one
    // red in the product. Colors.transparent is not a hue and is allowed.
    final violations = <String>[];
    final pattern = RegExp(
      r'\bColors\.(red|green|orange|blue|grey|gray|amber|purple|teal|yellow'
      r'|pink|cyan|indigo|brown|lime|deepOrange|deepPurple|lightBlue'
      r'|lightGreen|blueGrey)\b',
    );
    for (final file in [
      ...dartFilesUnder('features'),
      ...dartFilesUnder('core/presentation'),
    ]) {
      final src = file.readAsStringSync();
      for (final line in src.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (pattern.hasMatch(line)) violations.add('${file.path}: $trimmed');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('features do not build their own ThemeData or ColorScheme', () {
    // Both belong to AppTheme. A feature-local theme would fork the token
    // system, which is the failure the shared kit exists to prevent.
    final violations = <String>[];
    final pattern = RegExp(r'\b(ThemeData\(|ColorScheme\.fromSeed\()');
    for (final file in dartFilesUnder('features')) {
      final src = file.readAsStringSync();
      for (final line in src.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (pattern.hasMatch(line)) violations.add('${file.path}: $trimmed');
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

  test('schemaVersion remains 20', () {
    // A deliberate tripwire: bumping the version without adding an onUpgrade
    // step is how a released database silently fails to migrate. Change this
    // only alongside a migration and its test.
    final src = File('lib/core/database/app_database.dart').readAsStringSync();
    expect(src.contains('schemaVersion => 20'), isTrue);
    expect(src.contains('if (from <= 19)'), isTrue);
  });

  test(
    'shared presentation components do not import Drift or ledger writers',
    () {
      final violations = <String>[];
      for (final file in dartFilesUnder('core/presentation')) {
        final src = file.readAsStringSync();
        if (importsPackage(src, 'drift') ||
            RegExp(r'\bAppDatabase\b').hasMatch(src) ||
            src.contains('OperationsCompanion') ||
            src.contains('LedgerEntriesCompanion') ||
            src.contains('customStatement(')) {
          violations.add(file.path);
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );

  test(
    'presentation does not import feature data repository implementations',
    () {
      final violations = <String>[];
      final banned = RegExp(
        r"import\s+'package:family_money_manager/features/[^']+/data/"
        r"(drift_|.*_repository)",
      );
      for (final file in dartFilesUnder('features')) {
        if (!file.path.contains(
          '${Platform.pathSeparator}presentation'
          '${Platform.pathSeparator}',
        )) {
          continue;
        }
        if (file.path.endsWith('_providers.dart')) continue;
        final src = file.readAsStringSync();
        if (banned.hasMatch(src)) {
          violations.add(file.path);
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );

  test('account eligibility policy exists for ordinary endpoints', () {
    final src = File(
      'lib/features/accounts/domain/account_eligibility.dart',
    ).readAsStringSync();
    expect(src.contains('isOrdinaryTransactionEndpoint'), isTrue);
    expect(src.contains('isFeatureManagedType'), isTrue);
  });
}
