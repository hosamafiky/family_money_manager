import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/foundation_detail/foundation_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildDetailScreen({
  String probeId = 'test-probe',
  Locale locale = const Locale('en', 'US'),
}) {
  return ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(AppConfig.development)],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: FoundationDetailScreen(probeId: probeId),
    ),
  );
}

void main() {
  group('FoundationDetailScreen — typed-route parameter widget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildDetailScreen());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays probeId in body', (tester) async {
      await tester.pumpWidget(buildDetailScreen(probeId: 'abc-123'));
      await tester.pumpAndSettle();
      expect(find.textContaining('abc-123'), findsOneWidget);
    });

    testWidgets('different probeIds render different text', (tester) async {
      await tester.pumpWidget(buildDetailScreen(probeId: 'probe-alpha'));
      await tester.pumpAndSettle();
      expect(find.textContaining('probe-alpha'), findsOneWidget);
      expect(find.textContaining('probe-beta'), findsNothing);
    });

    testWidgets('shows localized title in English', (tester) async {
      await tester.pumpWidget(buildDetailScreen());
      await tester.pumpAndSettle();
      expect(find.text('Foundation Detail'), findsOneWidget);
    });

    testWidgets('shows localized title in Arabic', (tester) async {
      await tester.pumpWidget(
        buildDetailScreen(locale: const Locale('ar', 'EG')),
      );
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل البنية'), findsOneWidget);
    });

    testWidgets('does not display financial amounts or currency', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetailScreen(probeId: 'safe-probe'));
      await tester.pumpAndSettle();

      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(allText, isNot(contains('EGP')));
      expect(allText, isNot(matches(RegExp(r'\d{4,}'))));
    });
  });
}
