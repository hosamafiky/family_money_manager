import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
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

/// Redemption mode distinguishes what is being transferred.
enum _RedeemMode { principalOnly, profitOnly, combined }

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
      error: (_, __) => null,
    );

    if (progress != null && _principalCtrl.text.isEmpty) {
      final bal = progress.principalBalanceMinorUnits;
      final currency = progress.certificate.currencyCode;
      _principalCtrl.text = CertificateMoneyFormatter.format(bal, currency);
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
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.certificateRedeem,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            RadioListTile<_RedeemMode>(
              title: Text(l10n.certificateRedeemCombined),
              value: _RedeemMode.combined,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            ),
            RadioListTile<_RedeemMode>(
              title: Text(l10n.certificateRedeemPrincipalOnly),
              value: _RedeemMode.principalOnly,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            ),
            RadioListTile<_RedeemMode>(
              title: Text(l10n.certificateRedeemProfitOnly),
              value: _RedeemMode.profitOnly,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            ),
            const SizedBox(height: 12),
            if (_mode != _RedeemMode.profitOnly)
              TextFormField(
                controller: _principalCtrl,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.certificatePrincipalSection} (${progress?.currencyCode ?? ''})',
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
                  if (_mode == _RedeemMode.profitOnly) return null;
                  final d = double.tryParse(v ?? '');
                  return (d == null || d <= 0)
                      ? l10n.errorCertificatePrincipalZero
                      : null;
                },
              ),
            if (_mode != _RedeemMode.principalOnly) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _profitCtrl,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.certificateProfitSection} (${progress?.currencyCode ?? ''})',
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
                  if (_mode == _RedeemMode.principalOnly) return null;
                  final d = double.tryParse(v ?? '');
                  return (d == null || d < 0)
                      ? l10n.error_amount_must_be_positive
                      : null;
                },
              ),
            ],
            const SizedBox(height: 12),
            accountsAsync.when(
              data: (result) {
                if (result is! AppOk<List<FinancialAccount>>)
                  return const SizedBox();
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
                  value: _destinationAccountId,
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
                      v == null ? l10n.error_account_required : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
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
    final progressAsync = ref.watch(
      certificateProgressProvider(widget.certificateId),
    );
    final progress = progressAsync.when(
      data: (r) => r is AppOk<CertificateProgress> ? r.value : null,
      loading: () => null,
      error: (_, __) => null,
    );
    final currency = progress?.currencyCode ?? '';
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
          if (_mode != _RedeemMode.profitOnly)
            _ReviewRow(
              label: l10n.certificatePrincipalSection,
              value: '${_principalCtrl.text.trim()} $currency',
            ),
          if (_mode != _RedeemMode.principalOnly)
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

    final principalDouble = _mode != _RedeemMode.profitOnly
        ? (double.tryParse(_principalCtrl.text.trim()) ?? 0)
        : 0.0;
    final profitDouble = _mode != _RedeemMode.principalOnly
        ? (double.tryParse(_profitCtrl.text.trim()) ?? 0)
        : 0.0;

    final principalMinorUnits = (principalDouble * 100).round();
    final profitMinorUnits = (profitDouble * 100).round();

    // For profitOnly mode, we pass 1 as principal to satisfy the > 0 check
    // but the repository will only receive the validated amount.
    // Actually for profitOnly, we should record as a profit operation instead.
    // But per spec, redeem handles both. We pass 0 principal with profit only.

    final useCase = ref.read(redeemCertificateUseCaseProvider);
    final result = await useCase.execute(
      certificateId: widget.certificateId,
      householdId: _householdId,
      destinationAccountId: _destinationAccountId ?? '',
      principalMinorUnits: _mode == _RedeemMode.profitOnly
          ? 0
          : principalMinorUnits,
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
          AppValidationFailure(:final messageKey) => messageKey,
          _ => 'Error during redemption',
        };
      });
    }
  }

  String _modeLabel(AppLocalizations l10n, _RedeemMode mode) => switch (mode) {
    _RedeemMode.principalOnly => l10n.certificateRedeemPrincipalOnly,
    _RedeemMode.profitOnly => l10n.certificateRedeemProfitOnly,
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

// These keys exist in EN ARB — convenience accessors for this file.
extension on AppLocalizations {
  String get error_amount_must_be_positive => 'Amount must be positive';
  String get error_account_required => 'Account is required';
}
