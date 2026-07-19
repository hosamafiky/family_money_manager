import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Minimal screen that exists only to prove typed-route parameter serialization
/// and parsing in Phase 1.5.
///
/// This screen is not a product feature and will be replaced in a future phase
/// when real destination screens are implemented.
class FoundationDetailScreen extends StatelessWidget {
  const FoundationDetailScreen({required this.probeId, super.key});

  /// The parameter parsed from the typed route path.
  ///
  /// Must not carry financial data. Used only to demonstrate that typed-route
  /// parameters are correctly serialized into and parsed from the URL.
  final String probeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.foundationDetailTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Text(
            l10n.foundationDetailProbeLabel(probeId),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
