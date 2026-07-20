import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/certificate_money_formatter.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

class CertificateDetailScreen extends ConsumerWidget {
  const CertificateDetailScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(certificateProgressProvider(certificateId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.certificatesTitle),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(l10n.certificateLifecycleArchived),
              ),
              PopupMenuItem(
                value: 'restore',
                child: Text(l10n.certificateLifecycleActive),
              ),
            ],
            onSelected: (v) async {
              if (v == 'archive') {
                final uc = ref.read(archiveCertificateUseCaseProvider);
                await uc.execute(
                  certificateId: certificateId,
                  householdId: _householdId,
                );
                invalidateCertificateLifecycleProviders(
                  ref,
                  certificateId: certificateId,
                );
              } else if (v == 'restore') {
                final uc = ref.read(restoreCertificateUseCaseProvider);
                await uc.execute(
                  certificateId: certificateId,
                  householdId: _householdId,
                );
                invalidateCertificateLifecycleProviders(
                  ref,
                  certificateId: certificateId,
                );
              }
            },
          ),
        ],
      ),
      body: progressAsync.when(
        data: (result) {
          if (result is! AppOk<CertificateProgress>) {
            return Center(
              child: Text(
                result is AppNotFound ? 'Certificate not found' : 'Error',
              ),
            );
          }
          final progress = result.value;
          return _CertificateDetailBody(progress: progress);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: _CertificateDetailFab(
        certificateId: certificateId,
        progressAsync: progressAsync,
      ),
    );
  }
}

class _CertificateDetailBody extends StatelessWidget {
  const _CertificateDetailBody({required this.progress});

  final CertificateProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cert = progress.certificate;
    String fmt(int v) => CertificateMoneyFormatter.format(v, cert.currencyCode);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          children: [
            _Row(
              label: l10n.certificateInstitution,
              value: cert.institutionName,
            ),
            if (cert.reference != null)
              _Row(label: l10n.certificateReference, value: cert.reference!),
            _Row(
              label: l10n.certificatePrincipal,
              value:
                  '${fmt(cert.originalPrincipalMinorUnits)} ${cert.currencyCode}',
            ),
            _Row(
              label: l10n.certificatePrincipalBalance,
              value:
                  '${fmt(progress.principalBalanceMinorUnits)} ${cert.currencyCode}',
            ),
            _Row(label: l10n.certificateStartDate, value: cert.startDate),
            _Row(label: l10n.certificateMaturityDate, value: cert.maturityDate),
            _Row(
              label: l10n.certificateLifecycleActive,
              value: _lifecycleLabel(l10n, cert.lifecycle),
            ),
            _Row(
              label: l10n.certificateTermActive,
              value: _termLabel(l10n, progress.termState),
            ),
            if (cert.annualRateBps != null)
              _Row(
                label: l10n.certificateAnnualRate,
                value: '${cert.annualRateBps} bps',
              ),
            if (cert.profitFrequency != null)
              _Row(
                label: l10n.certificateProfitFrequency,
                value: _freqLabel(l10n, cert.profitFrequency!),
              ),
            if (cert.note != null)
              _Row(label: l10n.certificateNote, value: cert.note!),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.certificatesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...progress.events.map(
          (e) => Card(
            child: ListTile(
              leading: Icon(_eventIcon(e.eventType)),
              title: Text(e.eventType.code),
              subtitle: e.amountMinorUnits != null
                  ? Text(
                      '${CertificateMoneyFormatter.format(e.amountMinorUnits!, e.currencyCode ?? cert.currencyCode)} ${e.currencyCode ?? cert.currencyCode}',
                    )
                  : null,
              trailing: Text(e.effectiveAt.substring(0, 10)),
            ),
          ),
        ),
      ],
    );
  }

  String _lifecycleLabel(AppLocalizations l10n, CertificateLifecycle lc) =>
      switch (lc) {
        CertificateLifecycle.active => l10n.certificateLifecycleActive,
        CertificateLifecycle.redeemed => l10n.certificateLifecycleRedeemed,
        CertificateLifecycle.archived => l10n.certificateLifecycleArchived,
      };

  String _termLabel(AppLocalizations l10n, CertificateTermState s) =>
      switch (s) {
        CertificateTermState.notStarted => l10n.certificateTermNotStarted,
        CertificateTermState.activeTerm => l10n.certificateTermActive,
        CertificateTermState.matured => l10n.certificateTermMatured,
        CertificateTermState.overdueRedemption => l10n.certificateTermOverdue,
        CertificateTermState.fullyRedeemed => l10n.certificateTermFullyRedeemed,
      };

  String _freqLabel(AppLocalizations l10n, CertificateProfitFrequency f) =>
      switch (f) {
        CertificateProfitFrequency.monthly => l10n.certificateProfitFreqMonthly,
        CertificateProfitFrequency.quarterly =>
          l10n.certificateProfitFreqQuarterly,
        CertificateProfitFrequency.semiAnnual =>
          l10n.certificateProfitFreqSemiAnnual,
        CertificateProfitFrequency.annual => l10n.certificateProfitFreqAnnual,
        CertificateProfitFrequency.atMaturity =>
          l10n.certificateProfitFreqAtMaturity,
        CertificateProfitFrequency.other => l10n.certificateProfitFreqOther,
      };

  IconData _eventIcon(CertificateEventType t) => switch (t) {
    CertificateEventType.created => Icons.star,
    CertificateEventType.purchased => Icons.payment,
    CertificateEventType.profitReceived => Icons.trending_up,
    CertificateEventType.redeemed => Icons.account_balance_wallet,
    CertificateEventType.archived => Icons.archive_outlined,
    CertificateEventType.restored => Icons.unarchive_outlined,
    CertificateEventType.definitionRevised => Icons.edit_note,
    CertificateEventType.purchaseReversed => Icons.undo,
    CertificateEventType.profitReversed => Icons.remove_circle_outline,
  };
}

class _CertificateDetailFab extends ConsumerWidget {
  const _CertificateDetailFab({
    required this.certificateId,
    required this.progressAsync,
  });

  final String certificateId;
  final AsyncValue<AppResult<CertificateProgress>> progressAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = progressAsync.when(
      data: (r) => r is AppOk<CertificateProgress> ? r.value : null,
      loading: () => null,
      error: (_, _) => null,
    );
    if (progress == null) return const SizedBox();
    if (!progress.canRecordProfit && !progress.canRedeem) {
      return const SizedBox();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress.canRedeem)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.extended(
              heroTag: 'cert_detail_redeem_${certificateId.hashCode}',
              onPressed: () =>
                  context.push('/certificates/$certificateId/redeem'),
              icon: const Icon(Icons.account_balance_wallet),
              label: Text(l10n.certificateRedeem),
            ),
          ),
        if (progress.canRecordProfit)
          FloatingActionButton.extended(
            heroTag: 'cert_detail_profit_${certificateId.hashCode}',
            onPressed: () =>
                context.push('/certificates/$certificateId/profit'),
            icon: const Icon(Icons.trending_up),
            label: Text(l10n.certificateRecordProfit),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
