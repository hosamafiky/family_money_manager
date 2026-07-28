import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/certificate_money_formatter.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

class CertificatesListScreen extends ConsumerWidget {
  const CertificatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final certsAsync = ref.watch(certificatesProvider(_householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.certificatesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.certificateNew,
            onPressed: () => context.push('/certificates/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cert_list_fab',
        onPressed: () => context.push('/certificates/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.certificateNew),
      ),
      body: certsAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(
          message: l10n.errorGeneric,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(certificatesProvider(_householdId)),
        ),
        data: (result) {
          if (result is! AppOk<List<SavingsCertificate>>) {
            return AppEmptyState(
              title: l10n.certificateEmpty,
              icon: Icons.account_balance,
            );
          }
          final certs = result.value;
          if (certs.isEmpty) {
            return AppEmptyState(
              title: l10n.certificateEmpty,
              icon: Icons.account_balance,
              actionLabel: l10n.certificateNew,
              onAction: () => context.push('/certificates/new'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              100,
            ),
            itemCount: certs.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space8),
            itemBuilder: (context, i) => _CertificateCard(cert: certs[i]),
          );
        },
      ),
    );
  }
}

class _CertificateCard extends ConsumerWidget {
  const _CertificateCard({required this.cert});

  final SavingsCertificate cert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final progressAsync = ref.watch(certificateProgressProvider(cert.id));

    final termState = progressAsync.when(
      data: (r) => r is AppOk<CertificateProgress> ? r.value.termState : null,
      loading: () => null,
      error: (_, _) => null,
    );

    final principalBalance = progressAsync.when(
      data: (r) => r is AppOk<CertificateProgress>
          ? r.value.principalBalanceMinorUnits
          : null,
      loading: () => null,
      error: (_, _) => null,
    );

    final (lifecycleLabel, lifecycleColor) = switch (cert.lifecycle) {
      CertificateLifecycle.active => (
        l10n.certificateLifecycleActive,
        colors.certificatePrincipal,
      ),
      CertificateLifecycle.redeemed => (
        l10n.certificateLifecycleRedeemed,
        colors.neutralInfo,
      ),
      CertificateLifecycle.archived => (
        l10n.certificateLifecycleArchived,
        colors.disabled,
      ),
    };

    return Card(
      child: ListTile(
        onTap: () => context.push('/certificates/${cert.id}'),
        leading: CircleAvatar(
          backgroundColor: lifecycleColor.withValues(alpha: 0.15),
          child: Icon(Icons.account_balance, color: lifecycleColor),
        ),
        title: Text(cert.institutionName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.certificatePrincipal}: '
              '${CertificateMoneyFormatter.format(cert.originalPrincipalMinorUnits, cert.currencyCode)} '
              '${cert.currencyCode}',
            ),
            Text('${l10n.certificateMaturityDate}: ${cert.maturityDate}'),
            if (principalBalance != null)
              Text(
                '${l10n.certificatePrincipalBalance}: '
                '${CertificateMoneyFormatter.format(principalBalance, cert.currencyCode)}',
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lifecycleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lifecycleLabel,
                style: TextStyle(color: lifecycleColor, fontSize: 11),
              ),
            ),
            if (termState != null)
              Text(
                certificateTermStateLabel(l10n, termState),
                style: TextStyle(fontSize: 10, color: colors.secondaryText),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
