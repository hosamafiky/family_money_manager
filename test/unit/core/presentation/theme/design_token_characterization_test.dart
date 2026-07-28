/// Characterization tests for the design-token layer.
///
/// These assert what the tokens *are*, so that a token can never move by
/// accident. Each group names the migration phase that last settled it.
///
///   * colour roles — **settled in phase 1**. All 19 are literals.
///   * shape / spacing — **settled in phase 2**.
///   * text roles — **settled in phase 3**. Script-divergent metrics, both
///     bundled families applied.
///
/// A failure here means something drifted.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFinancialColors — nothing derives from a seed', () {
    // The whole point of phase 1. Eight roles used to read off
    // ColorScheme.fromSeed, which left the design at the mercy of Material's
    // palette generator. A literal cannot drift when Flutter retunes its
    // tonal algorithm.
    test('light palette is exactly the specified 19 values', () {
      const c = AppFinancialColors.light;
      expect(c.primaryAction, const Color(0xFF201E1D));
      expect(c.income, const Color(0xFF14555F));
      expect(c.expense, const Color(0xFFAE1800));
      expect(c.transfer, const Color(0xFF605D5D));
      expect(c.protectedMoney, const Color(0xFF6E4A1F));
      expect(c.goalReserved, const Color(0xFF2B5C8A));
      expect(c.certificatePrincipal, const Color(0xFF4A3E70));
      expect(c.warning, const Color(0xFF8A5A00));
      expect(c.success, const Color(0xFF0E5A44));
      expect(c.neutralInfo, const Color(0xFF3D4A52));
      expect(c.mainSurface, const Color(0xFFFFFFFF));
      expect(c.secondarySurface, const Color(0xFFEAE9E9));
      expect(c.divider, const Color(0xFFC3BFBE));
      expect(c.primaryText, const Color(0xFF201E1D));
      expect(c.secondaryText, const Color(0xFF575351));
      expect(c.disabled, const Color(0xFF9B9797));
      expect(c.ground, const Color(0xFFF3F2F2));
      expect(c.recessedSurface, const Color(0xFFDEDBDA));
      expect(c.focusRing, const Color(0xFFEC3013));
    });

    test('dark palette is exactly the specified 19 values', () {
      const c = AppFinancialColors.dark;
      expect(c.primaryAction, const Color(0xFFF0EDEB));
      expect(c.income, const Color(0xFF5FB8B0));
      expect(c.expense, const Color(0xFFFF9783));
      expect(c.transfer, const Color(0xFFB0ABA9));
      expect(c.protectedMoney, const Color(0xFFD6A85C));
      expect(c.goalReserved, const Color(0xFF7FAFDD));
      expect(c.certificatePrincipal, const Color(0xFFA99BD6));
      expect(c.warning, const Color(0xFFE0AE4A));
      expect(c.success, const Color(0xFF63BC94));
      expect(c.neutralInfo, const Color(0xFF9DB2BE));
      expect(c.mainSurface, const Color(0xFF221F1E));
      expect(c.secondarySurface, const Color(0xFF2C2928));
      expect(c.divider, const Color(0xFF4A4645));
      expect(c.primaryText, const Color(0xFFF0EDEB));
      expect(c.secondaryText, const Color(0xFFA8A3A0));
      expect(c.disabled, const Color(0xFF6B6766));
      expect(c.ground, const Color(0xFF181716));
      expect(c.recessedSurface, const Color(0xFF3A3635));
      expect(c.focusRing, const Color(0xFFFF563C));
    });

    test('every role is fully opaque', () {
      // disabled used to be onSurface at alpha 0.38. Alpha over the hatched
      // held region composited unpredictably, so it is now an opaque value.
      for (final c in [AppFinancialColors.light, AppFinancialColors.dark]) {
        for (final role in _allRoles(c)) {
          expect(role.a, 1.0, reason: 'every financial role must be opaque');
        }
      }
    });
  });

  group('AppFinancialColors — the distinctions the design depends on', () {
    // The properties that make the palette work. A future value change that
    // kept the hex codes plausible but broke one of these would be a
    // regression the literal assertions above could not catch.

    test('success is distinct from income in both themes', () {
      // Before phase 1 these were byte-identical, so a "saved" tick was
      // indistinguishable from an income amount — confirmation of a *write*
      // looked like confirmation of a *value*.
      for (final c in [AppFinancialColors.light, AppFinancialColors.dark]) {
        expect(c.success, isNot(c.income));
      }
    });

    test('the three surfaces are distinct in both themes', () {
      // ground / main / recessed carry the spendable-vs-held separation. If
      // any two collapse, the held-money region stops being a region.
      for (final c in [AppFinancialColors.light, AppFinancialColors.dark]) {
        expect({c.ground, c.mainSurface, c.recessedSurface}, hasLength(3));
      }
    });

    test('the direction axis is not green-vs-red', () {
      // The old palette put income and expense on precisely the axis both
      // common dichromacies collapse. income is now a deep teal, which
      // separates from the red on the blue–yellow channel they retain.
      const light = AppFinancialColors.light;
      expect(light.income.b, greaterThan(light.income.r));
      expect(light.expense.r, greaterThan(light.expense.b));
    });

    test(
      'transfer is achromatic — it changes no total, so it earns no hue',
      () {
        for (final c in [AppFinancialColors.light, AppFinancialColors.dark]) {
          expect(c.transfer.r, closeTo(c.transfer.g, 0.05));
          expect(c.transfer.g, closeTo(c.transfer.b, 0.05));
        }
      },
    );

    test('focusRing is not the expense red', () {
      // The ring is the one place raw accent appears outside the expense
      // role, because a focus ring is chrome, not money. Were they equal, a
      // focused field would read as an error.
      for (final c in [AppFinancialColors.light, AppFinancialColors.dark]) {
        expect(c.focusRing, isNot(c.expense));
      }
    });

    test('copyWith and lerp carry the roles added in phase 0', () {
      // A ThemeExtension that drops a field in copyWith or lerp fails silently
      // and only during a theme animation, which is close to undebuggable.
      const c = AppFinancialColors.light;
      const sentinel = Color(0xFF123456);

      final copied = c.copyWith(
        ground: sentinel,
        recessedSurface: sentinel,
        focusRing: sentinel,
      );
      expect(copied.ground, sentinel);
      expect(copied.recessedSurface, sentinel);
      expect(copied.focusRing, sentinel);

      final end = c.lerp(copied, 1.0);
      expect(end.ground, sentinel);
      expect(end.recessedSurface, sentinel);
      expect(end.focusRing, sentinel);
    });
  });

  group('AppTextRoles — metrics (settled in phase 3)', () {
    final latin = AppTextRoles.forLocale(
      AppTheme.light().colorScheme,
      const Locale('en'),
    );
    final arabic = AppTextRoles.forLocale(
      AppTheme.light(locale: const Locale('ar', 'EG')).colorScheme,
      const Locale('ar', 'EG'),
    );

    test('displayBalance', () {
      expect(latin.displayBalance.fontSize, 40);
      expect(latin.displayBalance.fontWeight, FontWeight.w800);
      expect(latin.displayBalance.height, 1.05);
      // Arabic is 2 px smaller and looser, to clear descending ligatures.
      expect(arabic.displayBalance.fontSize, 38);
      expect(arabic.displayBalance.fontWeight, FontWeight.w700);
      expect(arabic.displayBalance.height, 1.25);
    });

    test('screenTitle', () {
      expect(latin.screenTitle.fontSize, 25);
      expect(latin.screenTitle.fontWeight, FontWeight.w800);
      expect(arabic.screenTitle.fontSize, 24);
      expect(arabic.screenTitle.fontWeight, FontWeight.w700);
    });

    test(
      'sectionTitle — 13 px in both scripts, the rule carries hierarchy',
      () {
        // Shrank 18 → 13. Modernist's section heading is a small tracked label
        // above a 2 px rule; the rule carries the hierarchy, not the type size.
        expect(latin.sectionTitle.fontSize, 13);
        expect(arabic.sectionTitle.fontSize, 13);
        expect(latin.sectionTitle.fontWeight, FontWeight.w800);
        expect(arabic.sectionTitle.fontWeight, FontWeight.w700);
      },
    );

    test('cardTitle — Arabic stays a weight lighter', () {
      // Plex Arabic's 700 is optically heavier than Archivo's 800 at the same
      // optical size, so matching the numeric weight would over-bold Arabic.
      expect(latin.cardTitle.fontSize, 17);
      expect(latin.cardTitle.fontWeight, FontWeight.w800);
      expect(arabic.cardTitle.fontSize, 16);
      expect(arabic.cardTitle.fontWeight, FontWeight.w600);
    });

    test('body', () {
      expect(latin.body.fontSize, 15);
      expect(arabic.body.fontSize, 15);
      expect(latin.body.fontWeight, FontWeight.w400);
    });

    test('financialAmount', () {
      expect(latin.financialAmount.fontSize, 17);
      expect(arabic.financialAmount.fontSize, 17);
      expect(latin.financialAmount.fontWeight, FontWeight.w600);
      expect(arabic.financialAmount.fontWeight, FontWeight.w600);
    });

    test('supportingMeta — the one role where Arabic is larger', () {
      // 11 px Arabic loses tooth detail.
      expect(latin.supportingMeta.fontSize, 11);
      expect(arabic.supportingMeta.fontSize, 12);
      expect(
        arabic.supportingMeta.fontSize,
        greaterThan(latin.supportingMeta.fontSize!),
      );
    });

    test('formLabel — must not compete with the value in its field', () {
      expect(latin.formLabel.fontSize, 12);
      expect(arabic.formLabel.fontSize, 12);
      expect(latin.formLabel.fontWeight, FontWeight.w400);
    });

    test('buttonLabel', () {
      expect(latin.buttonLabel.fontSize, 14);
      expect(latin.buttonLabel.fontWeight, FontWeight.w800);
      expect(arabic.buttonLabel.fontSize, 14);
      expect(arabic.buttonLabel.fontWeight, FontWeight.w600);
    });

    test('statusLabel', () {
      expect(latin.statusLabel.fontSize, 11);
      expect(arabic.statusLabel.fontSize, 11);
      expect(latin.statusLabel.fontWeight, FontWeight.w600);
    });

    test('reportValue — grew 15 → 20', () {
      // It now carries the secondary-currency rows in the balance hero and
      // every metric value: the second-largest number allowed on a screen.
      expect(latin.reportValue.fontSize, 20);
      expect(arabic.reportValue.fontSize, 20);
      expect(latin.reportValue.fontWeight, FontWeight.w800);
      expect(arabic.reportValue.fontWeight, FontWeight.w700);
    });
  });

  group('AppTextRoles — the cross-script rules', () {
    final latin = AppTextRoles.forLocale(
      AppTheme.light().colorScheme,
      const Locale('en'),
    );
    final arabic = AppTextRoles.forLocale(
      AppTheme.light(locale: const Locale('ar', 'EG')).colorScheme,
      const Locale('ar', 'EG'),
    );

    test('Arabic never takes letter-spacing', () {
      // Tracking breaks the joins between Arabic characters. This is a
      // legibility bug, not a style preference, so it holds for every role.
      for (final style in _allTextRoles(arabic)) {
        expect(
          style.letterSpacing ?? 0,
          0,
          reason: 'no Arabic role may be letter-spaced',
        );
      }
    });

    test('Arabic line height exceeds Latin wherever they differ', () {
      // +0.30 across the board: diacritics and descending joins need the air.
      final pairs = <String, (TextStyle, TextStyle)>{
        'body': (latin.body, arabic.body),
        'formLabel': (latin.formLabel, arabic.formLabel),
        'supportingMeta': (latin.supportingMeta, arabic.supportingMeta),
        'sectionTitle': (latin.sectionTitle, arabic.sectionTitle),
        'cardTitle': (latin.cardTitle, arabic.cardTitle),
      };
      pairs.forEach((name, pair) {
        expect(pair.$2.height, greaterThan(pair.$1.height!), reason: name);
      });
    });

    test('every role carries a bundled family, and the other as fallback', () {
      // If a role fell back to a system font, a mixed Arabic-with-Latin-numeral
      // run would change metrics mid-line — inside a single amount.
      for (final style in _allTextRoles(latin)) {
        expect(style.fontFamily, latinFontFamily);
        expect(style.fontFamilyFallback, [arabicFontFamily]);
      }
      for (final style in _allTextRoles(arabic)) {
        expect(style.fontFamily, arabicFontFamily);
        expect(style.fontFamilyFallback, [latinFontFamily]);
      }
    });

    test('every money role is tabular and lining, in both scripts', () {
      // A column of amounts must align on the decimal at every size, and no
      // digit may sit below the baseline.
      const wanted = [
        FontFeature.tabularFigures(),
        FontFeature.liningFigures(),
      ];
      for (final roles in [latin, arabic]) {
        for (final style in [
          roles.displayBalance,
          roles.financialAmount,
          roles.reportValue,
        ]) {
          expect(style.fontFeatures, wanted);
        }
      }
    });

    test('displayBalance gained the figures it was missing', () {
      // It was the one money role without tabular figures before this phase.
      expect(
        latin.displayBalance.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('AppTextRoles — colour no longer derives from the seed', () {
    test('text roles take their colour from the literal palette', () {
      // Were these to derive from the neutrally-seeded ColorScheme, every text
      // role would be de-calibrated against the exact ground the design is
      // measured on.
      final light = AppTextRoles.forLocale(
        AppTheme.light().colorScheme,
        const Locale('en'),
      );
      expect(light.body.color, AppFinancialColors.light.primaryText);
      expect(
        light.supportingMeta.color,
        AppFinancialColors.light.secondaryText,
      );

      final dark = AppTextRoles.forLocale(
        AppTheme.dark().colorScheme,
        const Locale('en'),
      );
      expect(dark.body.color, AppFinancialColors.dark.primaryText);
      expect(dark.supportingMeta.color, AppFinancialColors.dark.secondaryText);
    });
  });

  group('AppTheme — shape and spacing (settled in phase 2)', () {
    test('every radius is zero except the sheet', () {
      expect(AppTheme.radiusBadge, 0.0);
      expect(AppTheme.radiusChip, 0.0);
      expect(AppTheme.radiusInput, 0.0);
      expect(AppTheme.radiusButton, 0.0);
      expect(AppTheme.radiusCard, 0.0);
      expect(AppTheme.radiusDialog, 0.0);
      // The one exception: a perfectly square sheet edge over a square
      // scaffold reads as a broken layout rather than as a layer.
      expect(AppTheme.radiusSheet, 2.0);
    });

    test('legacy radius aliases still resolve', () {
      expect(AppTheme.radiusSmall, 0.0);
      expect(AppTheme.radiusMedium, 0.0);
      expect(AppTheme.radiusLarge, 0.0);
      expect(AppTheme.radiusXLarge, AppTheme.radiusSheet);
    });

    test('the approved spacing scale, and only it', () {
      expect(
        [
          AppTheme.space4,
          AppTheme.space8,
          AppTheme.space12,
          AppTheme.space16,
          AppTheme.space20,
          AppTheme.space24,
          AppTheme.space32,
          AppTheme.space40,
        ],
        [4.0, 8.0, 12.0, 16.0, 20.0, 24.0, 32.0, 40.0],
      );
    });

    test('minTouchTarget survives the deletion of space48', () {
      // They shared a value, but one is a tap target and the other was a
      // spacing step off the approved scale. Only the spacing step went.
      expect(AppTheme.minTouchTarget, 48.0);
    });

    test('a region rule is 2 px', () {
      // The design's principal hierarchy device — it does the work M3 assigns
      // to elevation. Rows get a 1 px hairline; regions get ink.
      expect(AppTheme.regionRuleWidth, 2.0);
    });

    test('motion and content widths', () {
      expect(AppTheme.motionFast, const Duration(milliseconds: 150));
      expect(AppTheme.motionStandard, const Duration(milliseconds: 220));
      // Shortened in phase 3: 320 ms is noticeably slow on the app's single
      // most repeated transition.
      expect(AppTheme.motionEmphasized, const Duration(milliseconds: 280));

      expect(AppTheme.formContentMaxWidth, 720.0);
      expect(AppTheme.listContentMaxWidth, 960.0);
      // Phase 9 moves this to 905, above every phone landscape width.
      expect(AppTheme.railBreakpoint, 840.0);
    });
  });

  group('AppTheme — ThemeData wiring', () {
    test('the scaffold is the ground, and a card is not', () {
      // This is what `ground` was added for. With the page and a card on one
      // colour, card separation had to come from radius and shadow, both of
      // which the design removes.
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final financial = theme.extension<AppFinancialColors>()!;
        expect(theme.scaffoldBackgroundColor, financial.ground);
        expect(theme.scaffoldBackgroundColor, isNot(financial.mainSurface));
        expect(theme.cardTheme.color, financial.mainSurface);
      }
    });

    test('no component carries elevation', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.cardTheme.elevation, 0);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.dialogTheme.elevation, 0);
        expect(theme.bottomSheetTheme.elevation, 0);
      }
    });

    test('the card outline is a solid hairline, not half-alpha', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final financial = theme.extension<AppFinancialColors>()!;
        final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(shape.side.color, financial.divider);
        expect(shape.side.color.a, 1.0);
        expect(shape.borderRadius, BorderRadius.zero);
      }
    });

    test('focus is a 2 px ink bottom rule, not a 1.5 px box', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final financial = theme.extension<AppFinancialColors>()!;
        final focused = theme.inputDecorationTheme.focusedBorder!;
        expect(focused, isA<UnderlineInputBorder>());
        expect(focused.borderSide.width, AppTheme.regionRuleWidth);
        expect(focused.borderSide.color, financial.primaryAction);
      }
    });

    test('an errored field rules in the expense role', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final financial = theme.extension<AppFinancialColors>()!;
        expect(
          theme.inputDecorationTheme.errorBorder!.borderSide.color,
          financial.expense,
        );
      }
    });

    test('every ColorScheme role a stock widget can paint is pinned', () {
      // Seeding alone is not enough — M3 derives a chromatic primary from any
      // seed, including ink. Without these overrides an unrestyled Material
      // widget would render a tone the design system does not contain.
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final s = theme.colorScheme;
        final f = theme.extension<AppFinancialColors>()!;
        expect(s.primary, f.primaryAction);
        expect(s.surface, f.mainSurface);
        expect(s.onSurface, f.primaryText);
        expect(s.onSurfaceVariant, f.secondaryText);
        expect(s.outline, f.divider);
        expect(s.outlineVariant, f.divider);
        expect(s.error, f.expense);
      }
    });

    test('the scheme primary is achromatic, because it is ink', () {
      final s = AppTheme.light().colorScheme;
      expect(s.primary.r, closeTo(s.primary.g, 0.02));
      expect(s.primary.g, closeTo(s.primary.b, 0.02));
    });

    test('the stock error colour is the one product red, per theme', () {
      // Each theme takes its own expense value — the dark red is lighter so it
      // clears AA on the dark surface. What matters is that neither theme
      // introduces a *second* red.
      expect(AppTheme.light().colorScheme.error, const Color(0xFFAE1800));
      expect(AppTheme.dark().colorScheme.error, const Color(0xFFFF9783));
    });

    test('both extensions are registered on both themes', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.extension<AppFinancialColors>(), isNotNull);
        expect(theme.extension<AppTextRoles>(), isNotNull);
      }
    });

    test('light and dark resolve different palettes', () {
      expect(
        AppTheme.light().extension<AppFinancialColors>()!.ground,
        isNot(AppTheme.dark().extension<AppFinancialColors>()!.ground),
      );
    });

    test('the theme genuinely differs by locale', () {
      // If it did not, MaterialApp would have no reason to rebuild on a
      // language change and Arabic would render with Latin metrics.
      final english = AppTheme.light();
      final arabic = AppTheme.light(locale: const Locale('ar', 'EG'));

      expect(english.textTheme.bodyLarge!.fontFamily, latinFontFamily);
      expect(arabic.textTheme.bodyLarge!.fontFamily, arabicFontFamily);
      expect(
        arabic.extension<AppTextRoles>()!.body.height,
        greaterThan(english.extension<AppTextRoles>()!.body.height!),
      );
    });

    test('the app-bar title is smaller than screenTitle', () {
      // screenTitle moved into the body, flush to the leading margin. The bar
      // carries a smaller single-line style, so a truncated bar title never
      // loses information the body is not already showing.
      final theme = AppTheme.light();
      final roles = theme.extension<AppTextRoles>()!;
      expect(theme.appBarTheme.titleTextStyle!.fontSize, 18);
      expect(
        theme.appBarTheme.titleTextStyle!.fontSize,
        lessThan(roles.screenTitle.fontSize!),
      );
    });
  });
}

List<Color> _allRoles(AppFinancialColors c) => [
  c.primaryAction,
  c.income,
  c.expense,
  c.transfer,
  c.protectedMoney,
  c.goalReserved,
  c.certificatePrincipal,
  c.warning,
  c.success,
  c.neutralInfo,
  c.mainSurface,
  c.secondarySurface,
  c.divider,
  c.primaryText,
  c.secondaryText,
  c.disabled,
  c.ground,
  c.recessedSurface,
  c.focusRing,
];

List<TextStyle> _allTextRoles(AppTextRoles r) => [
  r.displayBalance,
  r.screenTitle,
  r.sectionTitle,
  r.cardTitle,
  r.body,
  r.financialAmount,
  r.supportingMeta,
  r.formLabel,
  r.buttonLabel,
  r.statusLabel,
  r.reportValue,
];
