/// Protected funds report screen.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_flow_row.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProtectedFundsReportScreen extends ConsumerWidget {
  const ProtectedFundsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(protectedFundsReportProvider(req));

    void retry() => ref.invalidate(protectedFundsReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportProtectedFundsTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.reportRefresh,
          onPressed: retry,
        ),
      ],
      body: Column(
        children: [
          const ReportPeriodSelector(),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () => AppLoadingState(message: l10n.loadingLabel),
              error: (_, _) => AppErrorState(
                message: l10n.reportError,
                onRetry: retry,
                retryLabel: l10n.reportRefresh,
              ),
              data: (result) {
                if (result is! AppOk<List<ProtectedFundsSummary>>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final funds = result.value;
                if (funds.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
                return _ProtectedFundsContent(funds: funds, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectedFundsContent extends StatelessWidget {
  const _ProtectedFundsContent({required this.funds, required this.l10n});

  final List<ProtectedFundsSummary> funds;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: AppInlineNotice(message: l10n.reportCurrencySeparate),
          ),
          for (final fund in funds) _FundFlow(fund: fund, l10n: l10n),
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _FundFlow extends StatelessWidget {
  const _FundFlow({required this.fund, required this.l10n});

  final ProtectedFundsSummary fund;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: fund.accountName),
        // Protected money is stated as held: it exists, and it cannot be
        // spent. That is a different thing from a spendable balance, and the
        // component says so with the lock rather than with a colour.
        balanceRow(
          label: l10n.reportOpeningBalance,
          minorUnits: fund.openingBalanceMinorUnits,
          currencyCode: fund.currencyCode,
        ),
        if (fund.fundingMinorUnits != 0)
          flowRow(
            label: l10n.reportFunded,
            magnitudeMinorUnits: fund.fundingMinorUnits,
            currencyCode: fund.currencyCode,
            direction: FinancialAmountDirection.inflow,
            tone: FinancialAmountTone.protected,
          ),
        if (fund.withdrawalMinorUnits != 0)
          flowRow(
            label: l10n.reportWithdrawals,
            magnitudeMinorUnits: fund.withdrawalMinorUnits,
            currencyCode: fund.currencyCode,
            direction: FinancialAmountDirection.outflow,
            tone: FinancialAmountTone.protected,
          ),
        if (fund.reversalEffectMinorUnits != 0)
          signedFlowRow(
            label: l10n.reportReversalEffect,
            signedMinorUnits: fund.reversalEffectMinorUnits,
            currencyCode: fund.currencyCode,
            tone: FinancialAmountTone.muted,
          ),
        balanceRow(
          label: l10n.reportPeriodClosingBalance,
          minorUnits: fund.closingBalanceMinorUnits,
          currencyCode: fund.currencyCode,
          isEmphasised: true,
        ),
        balanceRow(
          label: l10n.reportCurrentBalance,
          minorUnits: fund.currentBalanceMinorUnits,
          currencyCode: fund.currencyCode,
          isEmphasised: true,
          showDivider: false,
        ),
        if (fund.withdrawalAudits.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space16),
          SectionHeader(title: l10n.reportWithdrawals),
          for (final audit in fund.withdrawalAudits)
            _AuditRow(audit: audit, l10n: l10n),
        ],
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.audit, required this.l10n});

  final WithdrawalAuditSummary audit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // The caption is the audit trail: who it was for, who recorded it, when.
    // It printed a raw UUID for the beneficiary before, and never named the
    // recorder at all even though the column was already stored.
    final beneficiary = audit.beneficiaryName ?? audit.beneficiaryMemberId;
    final caption = audit.recordedByName == null
        ? l10n.reportAuditFor(beneficiary, audit.effectiveDate)
        : l10n.reportAuditForBy(
            beneficiary,
            audit.recordedByName!,
            audit.effectiveDate,
          );

    return CurrencyAmountRow(
      label: audit.reason,
      caption: caption,
      minorUnits: audit.amountMinorUnits,
      currencyCode: audit.currencyCode,
      tone: audit.isReversed
          ? FinancialAmountTone.muted
          : FinancialAmountTone.protected,
      direction: FinancialAmountDirection.outflow,
      semanticsContext: beneficiary,
    );
  }
}
