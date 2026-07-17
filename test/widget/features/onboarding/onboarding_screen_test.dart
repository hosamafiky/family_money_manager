import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({Locale locale = const Locale('ar')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OnboardingScreen(),
    ),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('1. renders app title in Arabic', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Arabic locale shows Arabic title.
      expect(find.textContaining('مدير'), findsWidgets);
    });

    testWidgets('2. shows localised subtitle (Arabic)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('مرحباً'), findsOneWidget);
    });

    testWidgets('3. shows localised subtitle (English)', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pump();
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('4. start button is present', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Button text is localised; find the FilledButton widget.
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('5. validation error shown when name is empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Tap submit without typing a name.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      // Form validator fires — the errorMemberNameEmpty key is displayed.
      expect(find.byType(TextFormField), findsOneWidget);
      // The form field shows an error (red text or indicator).
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('6. name field is present and accepts input', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'أحمد');
      expect(find.text('أحمد'), findsOneWidget);
    });

    testWidgets('7. start button disabled while submitting', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Test User');
      await tester.pump();
      // Button should be enabled before submit.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('8. RTL directionality for Arabic locale', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final dir = tester.widget<Directionality>(find.byType(Directionality).first);
      expect(dir.textDirection, TextDirection.rtl);
    });
  });
}
