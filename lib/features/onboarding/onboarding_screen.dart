import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/household/application/household_use_cases.dart';
import 'package:family_money_manager/features/household/data/drift_household_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown on first launch when no household exists.
///
/// Collects the primary user's name and initializes the household atomically.
/// On success navigates to /dashboard. Idempotent: safe to call if the
/// household already exists with the same name.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final name = _nameCtrl.text.trim();
    final db = ref.read(appDatabaseProvider);
    final useCase = InitializeHouseholdUseCase(householdRepository: DriftHouseholdRepository(db));
    final result = await useCase.execute(
      householdName: 'أسرتي',
      primaryMemberName: name,
      currencyCode: 'EGP',
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    switch (result) {
      case AppOk():
        context.go('/dashboard');
      case AppDuplicateConflict():
        context.go('/dashboard');
      case AppValidationFailure():
        setState(() {
          _loading = false;
          _error = l10n.errorMemberNameEmpty;
        });
      default:
        setState(() {
          _loading = false;
          _error = l10n.onboardingGenericError;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingNameLabel,
                    hintText: l10n.onboardingNameHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _loading ? null : _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.errorMemberNameEmpty;
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.onboardingStartButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
