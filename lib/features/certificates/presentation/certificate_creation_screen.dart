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

class CertificateCreationScreen extends ConsumerStatefulWidget {
  const CertificateCreationScreen({super.key});

  @override
  ConsumerState<CertificateCreationScreen> createState() =>
      _CertificateCreationScreenState();
}

class _CertificateCreationScreenState
    extends ConsumerState<CertificateCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _idempotencyKey;

  final _institutionCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _rateBpsCtrl = TextEditingController();

  String _currencyCode = 'EGP';
  String? _sourceAccountId;
  DateTime _startDate = DateTime.now();
  DateTime _maturityDate = DateTime.now().add(const Duration(days: 365));
  CertificateProfitFrequency? _profitFrequency;

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
    _institutionCtrl.dispose();
    _referenceCtrl.dispose();
    _principalCtrl.dispose();
    _noteCtrl.dispose();
    _rateBpsCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_showReview) return _buildReview(context, l10n);
    return _buildForm(context, l10n);
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificateNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _institutionCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificateInstitution,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.errorCertificateInstitutionRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenceCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificateReference,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _principalCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificatePrincipal,
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
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorCertificatePrincipalZero;
                }
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return l10n.errorCertificatePrincipalZero;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currencyCode,
              decoration: InputDecoration(
                labelText: l10n.certificateCurrencyRequired,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                DropdownMenuItem(value: 'AED', child: Text('AED')),
                DropdownMenuItem(value: 'KWD', child: Text('KWD')),
              ],
              onChanged: (v) => setState(() => _currencyCode = v ?? 'EGP'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.certificateStartDate),
              subtitle: Text(_dateStr(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            ListTile(
              title: Text(l10n.certificateMaturityDate),
              subtitle: Text(_dateStr(_maturityDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _maturityDate,
                  firstDate: _startDate.add(const Duration(days: 1)),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _maturityDate = d);
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
                          !a.isProtected &&
                          a.type != FinancialAccountType.goalReserve &&
                          a.type != FinancialAccountType.certificate &&
                          a.currencyCode == _currencyCode,
                    )
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _sourceAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.certificateSourceAccount,
                    border: const OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _sourceAccountId = v),
                  validator: (v) =>
                      v == null ? l10n.errorCertificateSourceRequired : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateBpsCtrl,
              decoration: InputDecoration(
                labelText: l10n.certificateAnnualRate,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CertificateProfitFrequency?>(
              initialValue: _profitFrequency,
              decoration: InputDecoration(
                labelText: l10n.certificateProfitFrequency,
                border: const OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...CertificateProfitFrequency.values.map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(_freqLabel(l10n, f)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _profitFrequency = v),
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
            label: l10n.certificateInstitution,
            value: _institutionCtrl.text.trim(),
          ),
          if (_referenceCtrl.text.trim().isNotEmpty)
            _ReviewRow(
              label: l10n.certificateReference,
              value: _referenceCtrl.text.trim(),
            ),
          _ReviewRow(
            label: l10n.certificatePrincipal,
            value: '${_principalCtrl.text.trim()} $_currencyCode',
          ),
          _ReviewRow(
            label: l10n.certificateStartDate,
            value: _dateStr(_startDate),
          ),
          _ReviewRow(
            label: l10n.certificateMaturityDate,
            value: _dateStr(_maturityDate),
          ),
          if (_rateBpsCtrl.text.trim().isNotEmpty)
            _ReviewRow(
              label: l10n.certificateAnnualRate,
              value: _rateBpsCtrl.text.trim(),
            ),
          if (_profitFrequency != null)
            _ReviewRow(
              label: l10n.certificateProfitFrequency,
              value: _freqLabel(l10n, _profitFrequency!),
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
                : Text(l10n.certificateNew),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() != true) return;
    if (_maturityDate.compareTo(_startDate) <= 0) {
      final l10n = AppLocalizations.of(context);
      setState(() => _errorMessage = l10n.errorCertificateMaturityBeforeStart);
      return;
    }
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
    final principalDouble = double.tryParse(_principalCtrl.text.trim()) ?? 0;
    final principalMinorUnits = (principalDouble * 100).round();
    final rateBps = int.tryParse(_rateBpsCtrl.text.trim());

    final useCase = ref.read(createCertificateUseCaseProvider);
    final result = await useCase.execute(
      householdId: _householdId,
      institutionName: _institutionCtrl.text.trim(),
      currencyCode: _currencyCode,
      principalMinorUnits: principalMinorUnits,
      startDate: _dateStr(_startDate),
      maturityDate: _dateStr(_maturityDate),
      sourceAccountId: _sourceAccountId ?? '',
      idempotencyKey: _idempotencyKey,
      reference: _referenceCtrl.text.trim().isNotEmpty
          ? _referenceCtrl.text.trim()
          : null,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      annualRateBps: rateBps,
      profitFrequency: _profitFrequency,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AppOk<SavingsCertificate>) {
      ref.invalidate(certificatesProvider(_householdId));
      invalidateCertificateMoneyProviders(ref, certificateId: result.value.id);
      context.pop();
    } else {
      // Regenerate key on hard failure to allow retry.
      _idempotencyKey = const Uuid().v4();
      setState(() {
        _errorMessage = switch (result) {
          AppInsufficientFunds() => l10n.errorGoalInsufficientReserve,
          AppValidationFailure(:final messageKey) => messageKey,
          AppDuplicateConflict(:final messageKey) => messageKey,
          _ => 'Unexpected error',
        };
      });
    }
  }

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

// ignore: unused_element - accessed via getter for localization key string
extension on AppLocalizations {
  String get certificateCurrencyRequired => errorCertificateCurrencyRequired;
}
