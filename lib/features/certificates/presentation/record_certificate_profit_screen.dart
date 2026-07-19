import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';

class RecordCertificateProfitScreen extends ConsumerStatefulWidget {
  const RecordCertificateProfitScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  ConsumerState<RecordCertificateProfitScreen> createState() =>
      _RecordCertificateProfitScreenState();
}

class _RecordCertificateProfitScreenState
    extends ConsumerState<RecordCertificateProfitScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _idempotencyKey;

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _destinationAccountId;
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
    _amountCtrl.dispose();
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
    final certAsync = ref.watch(
      certificateDetailProvider(widget.certificateId),
    );
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    final cert = certAsync.when(
      data: (r) => r is AppOk<SavingsCertificate?> ? r.value : null,
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificateProfitTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (cert != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${cert.institutionName} — ${cert.currencyCode}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificateAmount,
                border: const OutlineInputBorder(),
                suffixText: cert?.currencyCode,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textInputAction: TextInputAction.next,
              validator: (v) {
                final d = double.tryParse(v ?? '');
                return (d == null || d <= 0)
                    ? l10n.error_amount_must_be_positive
                    : null;
              },
            ),
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
                          (cert == null || a.currencyCode == cert.currencyCode),
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
                      v == null ? l10n.error_account_required : null,
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
    final certAsync = ref.watch(
      certificateDetailProvider(widget.certificateId),
    );
    final cert = certAsync.when(
      data: (r) => r is AppOk<SavingsCertificate?> ? r.value : null,
      loading: () => null,
      error: (_, _) => null,
    );
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
            label: l10n.certificateAmount,
            value: '${_amountCtrl.text.trim()} ${cert?.currencyCode ?? ''}',
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
                : Text(l10n.certificateRecordProfit),
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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final l10n = AppLocalizations.of(context);
    final amountDouble = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final amountMinorUnits = (amountDouble * 100).round();

    final useCase = ref.read(recordCertificateProfitUseCaseProvider);
    final result = await useCase.execute(
      certificateId: widget.certificateId,
      householdId: _householdId,
      destinationAccountId: _destinationAccountId ?? '',
      amountMinorUnits: amountMinorUnits,
      idempotencyKey: _idempotencyKey,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AppOk<CertificateProfitReceipt>) {
      invalidateCertificateMoneyProviders(
        ref,
        certificateId: widget.certificateId,
      );
      context.pop();
    } else {
      _idempotencyKey = const Uuid().v4();
      setState(() {
        _errorMessage = switch (result) {
          AppValidationFailure(:final messageKey) => messageKey,
          AppNotFound() => 'Not found',
          _ => 'Error recording profit',
        };
      });
    }
  }
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

// These keys exist in the EN ARB — re-exported for use in this file.
extension on AppLocalizations {
  String get error_amount_must_be_positive => 'Amount must be positive';
  String get error_account_required => 'Account is required';
}
