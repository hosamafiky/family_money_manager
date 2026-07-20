/// Phase 6A.1 — widget proof that profit-only is not on redeem screen.
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:family_money_manager/features/certificates/presentation/redeem_certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

SavingsCertificate _cert(String id) => SavingsCertificate(
  id: id,
  householdId: 'household-v1',
  certificateAccountId: 'cert-acc',
  currencyCode: 'EGP',
  originalPrincipalMinorUnits: 100000,
  startDate: '2024-01-01',
  maturityDate: '2025-01-01',
  lifecycle: CertificateLifecycle.active,
  currentRevision: const CertificateRevision(
    id: 'rev',
    certificateId: 'c1',
    householdId: 'household-v1',
    institutionName: 'National Bank',
    createdAt: '2024-01-01T00:00:00Z',
    revisionReason: 'initial',
  ),
  createdAt: '2024-01-01T00:00:00Z',
  idempotencyKey: 'ik',
  schemaVersion: 1,
);

void main() {
  testWidgets(
    'WF-UI-1. Redeem screen has no profit-only mode; links to profit',
    (tester) async {
      final cert = _cert('c1');
      final progress = CertificateProgress(
        certificate: cert,
        principalBalanceMinorUnits: 100000,
        currencyCode: 'EGP',
        termState: CertificateTermState.matured,
        events: const [],
        revisions: [cert.currentRevision],
        todayLocal: '2025-06-15',
      );
      const account = FinancialAccount(
        id: 'dst',
        householdId: 'household-v1',
        name: 'Cash',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        isArchived: false,
        displayOrder: 0,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
        createdBy: 'test',
      );

      final router = GoRouter(
        initialLocation: '/certificates/c1/redeem',
        routes: [
          GoRoute(
            path: '/certificates/:id/redeem',
            builder: (_, state) => RedeemCertificateScreen(
              certificateId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/certificates/:id/profit',
            builder: (_, _) => const Scaffold(body: Text('ProfitRoute')),
          ),
        ],
      );

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
            certificateProgressProvider.overrideWith(
              (ref, id) async => AppOk(progress),
            ),
            accountsProvider.overrideWith(
              (ref, hh) async => const AppOk([account]),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profit only'), findsNothing);
      expect(find.text('Record Profit'), findsOneWidget);
      expect(find.textContaining('Principal'), findsWidgets);

      await tester.tap(find.text('Record Profit'));
      await tester.pumpAndSettle();
      expect(find.text('ProfitRoute'), findsOneWidget);
    },
  );
}
