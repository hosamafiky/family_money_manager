import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/resolve_message_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('resolveMessageKey', () {
    testWidgets('maps legacy snake_case keys in Arabic', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        _wrap(
          const Locale('ar', 'EG'),
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        resolveMessageKey(l10n, 'error_amount_must_be_positive'),
        l10n.errorAmountMustBePositive,
      );
      expect(
        resolveMessageKey(l10n, 'error_account_required'),
        l10n.errorAccountRequired,
      );
      expect(
        resolveMessageKey(l10n, 'errorGoalNotActive'),
        l10n.errorGoalNotActive,
      );
    });

    testWidgets('falls back to generic message for unknown keys', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        _wrap(
          const Locale('en', 'US'),
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        resolveMessageKey(l10n, 'totally_unknown_key'),
        l10n.errorGeneric,
      );
    });
  });
}
