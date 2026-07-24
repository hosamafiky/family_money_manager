import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/resolve_message_key.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/certificate_money_formatter.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';

/// Redemption mode: full remaining principal, optionally with maturity profit.
///
/// Profit-only receipts use [RecordCertificateProfitScreen] — never this screen.
enum _RedeemMode { principalOnly, combined }

class RedeemCertificateScreen extends ConsumerStatefulWidget {
  const RedeemCertificateScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  ConsumerState<RedeemCertificateScreen> createState() =>
      _RedeemCertificateScreenState();
}

class _RedeemCertificateScreenState
    extends ConsumerState<RedeemCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _idempotencyKey;

  final _principalCtrl = TextEditingController();
  final _profitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _destinationAccountId;
  _RedeemMode _mode = _RedeemMode.combined;
  bool _loading = false;
  bool _showReview = false;
  String? _errorMessage;
  int? _lockedPrincipalMinorUnits;
  String? _currencyCode;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _profitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_showReview) return _buildReview(context, l10n);
    return _buildForm(context, l10n);
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final progressAsync = ref.watch(
      certificateProgressProvider(widget.certificateId),
    );
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    final progress = progressAsync.when(
      data: (r) => r is AppOk<CertificateProgress> ? r.value : null,
      loading: () => null,
      error: (_, _) => null,
    );

    if (progress != null && _lockedPrincipalMinorUnits == null) {
      _lockedPrincipalMinorUnits = progress.principalBalanceMinorUnits;
      _currencyCode = progress.currencyCode;
      _principalCtrl.text = CertificateMoneyFormatter.format(
        progress.principalBalanceMinorUnits,
        progress.currencyCode,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificateRedeemTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (progress != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.certificate.institutionName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${l10n.certificatePrincipalBalance}: '
                        '${CertificateMoneyFormatter.format(progress.principalBalanceMinorUnits, progress.currencyCode)} '
                        '${progress.currencyCode}',
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.push(
                          '/certificates/${widget.certificateId}/profit',
                        ),
                        child: Text(l10n.certificateRecordProfit),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.certificateRedeem,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            RadioGroup<_RedeemMode>(
              groupValue: _mode,
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
              child: Column(
                children: [
                  RadioListTile<_RedeemMode>(
                    title: Text(l10n.certificateRedeemCombined),
                    value: _RedeemMode.combined,
                  ),
                  RadioListTile<_RedeemMode>(
                    title: Text(l10n.certificateRedeemPrincipalOnly),
                    value: _RedeemMode.principalOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _principalCtrl,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText:
                    '${l10n.certificatePrincipalSection} (${_currencyCode ?? progress?.currencyCode ?? ''})',
                border: const OutlineInputBorder(),
                helperText: l10n.certificatePrincipalBalance,
              ),
            ),
            if (_mode == _RedeemMode.combined) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _profitCtrl,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.certificateProfitSection} (${_currencyCode ?? progress?.currencyCode ?? ''})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v);
                  return (d == null || d < 0)
                      ? l10n.errorAmountMustBePositive
                      : null;
                },
              ),
            ],
            const SizedBox(height: 12),
            accountsAsync.when(
              data: (result) {
                if (result is! AppOk<List<FinancialAccount>>) {
                  return const SizedBox();
                }
                final accounts = result.value
                    .where(
                      (a) =>
                          !a.isArchived &&
                          a.type != FinancialAccountType.goalReserve &&
                          a.type != FinancialAccountType.certificate &&
                          (progress == null ||
                              a.currencyCode == progress.currencyCode),
                    )
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _destinationAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.certificateDestinationAccount,
                    border: const OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _destinationAccountId = v),
                  validator: (v) =>
                      v == null ? l10n.errorAccountRequired : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificateNote,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _onContinue,
              child: Text(l10n.certificateReviewTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context, AppLocalizations l10n) {
    final currency = _currencyCode ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.certificateReviewTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showReview = false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReviewRow(
            label: l10n.certificateRedeem,
            value: _modeLabel(l10n, _mode),
          ),
          _ReviewRow(
            label: l10n.certificatePrincipalSection,
            value: '${_principalCtrl.text.trim()} $currency',
          ),
          if (_mode == _RedeemMode.combined &&
              _profitCtrl.text.trim().isNotEmpty)
            _ReviewRow(
              label: l10n.certificateProfitSection,
              value: '${_profitCtrl.text.trim()} $currency',
            ),
          if (_noteCtrl.text.trim().isNotEmpty)
            _ReviewRow(
              label: l10n.certificateNote,
              value: _noteCtrl.text.trim(),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _onSubmit,
            child: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.certificateRedeem),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _errorMessage = null;
      _showReview = true;
    });
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final principalMinorUnits = _lockedPrincipalMinorUnits ?? 0;
    final profitDouble = _mode == _RedeemMode.combined
        ? (double.tryParse(_profitCtrl.text.trim()) ?? 0)
        : 0.0;
    final profitMinorUnits = (profitDouble * 100).round();

    final useCase = ref.read(redeemCertificateUseCaseProvider);
    final result = await useCase.execute(
      certificateId: widget.certificateId,
      householdId: _householdId,
      destinationAccountId: _destinationAccountId ?? '',
      principalMinorUnits: principalMinorUnits,
      profitMinorUnits: profitMinorUnits,
      idempotencyKey: _idempotencyKey,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AppOk<CertificateRedemptionSummary>) {
      invalidateCertificateMoneyProviders(
        ref,
        certificateId: widget.certificateId,
      );
      context.pop();
      context.pop(); // Back to list
    } else {
      _idempotencyKey = const Uuid().v4();
      setState(() {
        _errorMessage = switch (result) {
          AppInsufficientFunds() => l10n.errorGoalInsufficientReserve,
          AppValidationFailure(:final messageKey) => resolveMessageKey(
            l10n,
            messageKey,
          ),
          _ => l10n.errorGeneric,
        };
      });
    }
  }

  String _modeLabel(AppLocalizations l10n, _RedeemMode mode) => switch (mode) {
    _RedeemMode.principalOnly => l10n.certificateRedeemPrincipalOnly,
    _RedeemMode.combined => l10n.certificateRedeemCombined,
  };
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
