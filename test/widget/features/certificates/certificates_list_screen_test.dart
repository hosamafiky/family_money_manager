/// Widget tests for CertificatesListScreen.
///
/// Tests:
///  1. Loading state shown (CircularProgressIndicator)
///  2. Empty state shown with create button
///  3. Error state shown
///  4. Certificate card shows institution name and principal
///  5. Lifecycle badge shown on card (EN)
///  6. Arabic RTL: title is the Arabic translation
///  7. English LTR: title is "Certificates"
///  8. FAB present with heroTag cert_list_fab
///  9. Tap card navigates to detail route
/// 10. Two certificates at different currencies shown on same list
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/certificates_list_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._mode);
  final ThemeMode _mode;
  @override
  ThemeMode build() => _mode;
}

SavingsCertificate _fakeCert({
  String id = 'c-1',
  String institution = 'National Bank',
  String currency = 'EGP',
  int principal = 100000,
  CertificateLifecycle lifecycle = CertificateLifecycle.active,
}) {
  final rev = CertificateRevision(
    id: 'rev-$id',
    certificateId: id,
    householdId: 'household-v1',
    institutionName: institution,
    createdAt: '2025-01-01T00:00:00Z',
    revisionReason: 'initial',
  );
  return SavingsCertificate(
    id: id,
    householdId: 'household-v1',
    certificateAccountId: 'cert-acc-$id',
    currencyCode: currency,
    originalPrincipalMinorUnits: principal,
    startDate: '2025-01-01',
    maturityDate: '2026-01-01',
    lifecycle: lifecycle,
    currentRevision: rev,
    createdAt: '2025-01-01T00:00:00Z',
    idempotencyKey: 'ik-$id',
    schemaVersion: 1,
  );
}

CertificateProgress _fakeProgress(
  SavingsCertificate cert, {
  int balance = 100000,
}) => CertificateProgress(
  certificate: cert,
  principalBalanceMinorUnits: balance,
  currencyCode: cert.currencyCode,
  termState: CertificateTermState.activeTerm,
  events: const [],
  revisions: [cert.currentRevision],
  todayLocal: '2025-06-15',
);

GoRouter _makeRouter({String initialLocation = '/certificates'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/certificates',
      builder: (_, _) => const CertificatesListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, _) => const Scaffold(body: Text('CreateCertificate')),
        ),
        GoRoute(
          path: ':certId',
          builder: (context, state) => Scaffold(
            body: Text('CertDetail:${state.pathParameters['certId']}'),
          ),
        ),
      ],
    ),
  ],
);

MaterialApp _appShell(GoRouter router, Locale locale) => MaterialApp.router(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('CertificatesListScreen', () {
    testWidgets('1. Loading state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) =>
                  Completer<AppResult<List<SavingsCertificate>>>().future,
            ),
            certificateProgressProvider.overrideWith(
              (ref, _) => Completer<AppResult<CertificateProgress>>().future,
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('2. Empty state shown with create button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) async => const AppOk(<SavingsCertificate>[]),
            ),
            certificateProgressProvider.overrideWith(
              (ref, _) async => Future.error('not needed'),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No certificates'), findsOneWidget);
      expect(find.text('New Certificate'), findsWidgets);
    });

    testWidgets('3. Error state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) => Future.error(Exception('DB error')),
            ),
            certificateProgressProvider.overrideWith(
              (ref, _) => Future.error(Exception('progress error')),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
    });

    testWidgets('4. Certificate card shows institution name and principal', (
      tester,
    ) async {
      final cert = _fakeCert(
        institution: 'First Bank',
        currency: 'EGP',
        principal: 500000,
      );
      final progress = _fakeProgress(cert);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith((ref, _) async => AppOk([cert])),
            certificateProgressProvider.overrideWith(
              (ref, _) async => AppOk(progress),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First Bank'), findsOneWidget);
      expect(find.textContaining('EGP'), findsWidgets);
    });

    testWidgets('5. Lifecycle badge shown on card (EN active)', (tester) async {
      final cert = _fakeCert(lifecycle: CertificateLifecycle.active);
      final progress = _fakeProgress(cert);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith((ref, _) async => AppOk([cert])),
            certificateProgressProvider.overrideWith(
              (ref, _) async => AppOk(progress),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('6. Arabic RTL: title is Arabic translation', (tester) async {
      final cert = _fakeCert();
      final progress = _fakeProgress(cert);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('ar')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith((ref, _) async => AppOk([cert])),
            certificateProgressProvider.overrideWith(
              (ref, _) async => AppOk(progress),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('ar')),
        ),
      );
      await tester.pumpAndSettle();

      // Arabic translation for certificatesTitle should be present.
      expect(find.textContaining('شهادات'), findsWidgets);
    });

    testWidgets('7. English LTR: title is "Certificates"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) async => const AppOk(<SavingsCertificate>[]),
            ),
            certificateProgressProvider.overrideWith(
              (ref, _) => Future.error('n/a'),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Certificates'), findsOneWidget);
    });

    testWidgets('8. FAB present with heroTag cert_list_fab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) async => const AppOk(<SavingsCertificate>[]),
            ),
            certificateProgressProvider.overrideWith(
              (ref, _) => Future.error('n/a'),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, 'cert_list_fab');
    });

    testWidgets('9. Tap card navigates to detail route', (tester) async {
      final cert = _fakeCert(id: 'c-tap', institution: 'Tap Bank');
      final progress = _fakeProgress(cert);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith((ref, _) async => AppOk([cert])),
            certificateProgressProvider.overrideWith(
              (ref, _) async => AppOk(progress),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Bank'));
      await tester.pumpAndSettle();

      expect(find.text('CertDetail:c-tap'), findsOneWidget);
    });

    testWidgets('10. Two certificates at different currencies on same list', (
      tester,
    ) async {
      final certEgp = _fakeCert(
        id: 'c-egp',
        institution: 'EGP Bank',
        currency: 'EGP',
      );
      final certUsd = _fakeCert(
        id: 'c-usd',
        institution: 'USD Bank',
        currency: 'USD',
      );
      final progressEgp = _fakeProgress(certEgp);
      final progressUsd = _fakeProgress(certUsd);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            certificatesProvider.overrideWith(
              (ref, _) async => AppOk([certEgp, certUsd]),
            ),
            certificateProgressProvider.overrideWith((ref, certId) async {
              if (certId == 'c-egp') return AppOk(progressEgp);
              return AppOk(progressUsd);
            }),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EGP Bank'), findsOneWidget);
      expect(find.text('USD Bank'), findsOneWidget);
      expect(find.textContaining('EGP'), findsWidgets);
      expect(find.textContaining('USD'), findsWidgets);
    });
  });
}
