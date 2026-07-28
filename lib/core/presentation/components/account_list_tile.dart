/// The account tile, and the six visual classes that make "can I spend this?"
/// answerable without reading a word.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/components/hatch_pattern.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Which region a tile is allowed to appear in.
///
/// Held money never appears in the same list as spendable money — not greyed
/// out inside it, not sorted to the bottom of it. It lives below a 2 px rule,
/// on the recessed surface, under its own heading, and it is never summed with
/// anything above that rule.
enum AccountRegion { spendable, held }

/// The six visual classes an account tile can take.
///
/// A class is not a colour swatch. It is a leading-edge treatment, plus a
/// glyph, plus which region the tile may appear in — so the distinction
/// survives greyscale, privacy mode and a screen reader.
///
/// The screen decides which class an account has, from domain data. The tile
/// never inspects an account type, a balance or an owner to work it out.
enum AccountVisualClass {
  cash(
    region: AccountRegion.spendable,
    edge: EdgeTreatment.solid,
    icon: Icons.account_balance_wallet_outlined,
  ),
  bank(
    region: AccountRegion.spendable,
    edge: EdgeTreatment.solid,
    icon: Icons.account_balance_outlined,
  ),

  /// Spendable, but deliberately excluded from "available to spend": telling
  /// one household member's money from another's is the point of the row.
  spouseWallet(
    region: AccountRegion.spendable,
    edge: EdgeTreatment.solid,
    icon: Icons.account_balance_wallet_outlined,
  ),

  certificatePrincipal(
    region: AccountRegion.held,
    edge: EdgeTreatment.hatched,
    icon: Icons.verified_outlined,
  ),
  goalReserve(
    region: AccountRegion.held,
    edge: EdgeTreatment.hatched,
    icon: Icons.flag_outlined,
  ),

  /// The deepest treatment in the product: a hatched edge like the other held
  /// classes, plus a 2 px frame around the whole tile. A withdrawal from here
  /// requires an acknowledgement naming the child.
  protectedFund(
    region: AccountRegion.held,
    edge: EdgeTreatment.hatched,
    icon: Icons.lock_outline,
  );

  const AccountVisualClass({
    required this.region,
    required this.edge,
    required this.icon,
  });

  final AccountRegion region;
  final EdgeTreatment edge;
  final IconData icon;

  bool get isHeld => region == AccountRegion.held;

  /// Only protected funds are framed.
  ///
  /// The frame is on the tile rather than on its leading edge because the edge
  /// is 4 dp: a 2 px stroke inside it consumes the whole width and hides the
  /// hatch, which would make protected money indistinguishable from a solid
  /// spendable edge — the opposite of what the treatment is for.
  bool get isFramed => this == AccountVisualClass.protectedFund;
}

enum EdgeTreatment { solid, hatched }

/// A single account, in its region.
///
/// Intrinsic height with a 64 dp minimum — long Arabic names wrap to three
/// lines and the tile grows rather than truncating them.
class AccountListTile extends StatelessWidget {
  const AccountListTile({
    required this.name,
    required this.visualClass,
    required this.minorUnits,
    required this.currencyCode,
    required this.subtitle,
    super.key,
    this.isArchived = false,
    this.trailingBadge,
    this.onTap,
    this.semanticsContext,
  });

  final String name;
  final AccountVisualClass visualClass;
  final int minorUnits;
  final String currencyCode;

  /// The meta line: type, owner, and any restriction that applies. Already
  /// localised and already assembled by the screen.
  final String subtitle;

  /// Archived accounts keep their history and become read-only. They collapse
  /// into a group at the end of the list and take an outline-only edge.
  final bool isArchived;

  final Widget? trailingBadge;
  final VoidCallback? onTap;
  final String? semanticsContext;

  /// Minimum, never fixed.
  static const double minHeight = 64;

  /// Leading-edge width. Doubles as the tile's primary non-colour signal.
  static const double edgeWidth = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;

    final roleColor = switch (visualClass) {
      AccountVisualClass.cash ||
      AccountVisualClass.bank ||
      AccountVisualClass.spouseWallet => colors.primaryText,
      AccountVisualClass.certificatePrincipal => colors.certificatePrincipal,
      AccountVisualClass.goalReserve => colors.goalReserved,
      AccountVisualClass.protectedFund => colors.protectedMoney,
    };

    final tone = switch (visualClass) {
      AccountVisualClass.cash ||
      AccountVisualClass.bank ||
      AccountVisualClass.spouseWallet => FinancialAmountTone.neutral,
      AccountVisualClass.certificatePrincipal =>
        FinancialAmountTone.certificate,
      AccountVisualClass.goalReserve => FinancialAmountTone.goal,
      AccountVisualClass.protectedFund => FinancialAmountTone.protected,
    };

    return Semantics(
      button: onTap != null,
      container: true,
      // The class leads, so a screen-reader user learns whether the money is
      // spendable before hearing the name or the figure.
      label: [
        name,
        subtitle,
        if (semanticsContext case final String extra) extra,
      ].join(', '),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          // A tonal press, not a ripple: an expanding circle contradicts a
          // square system, and on a money row it reads as something happening
          // to the money.
          splashFactory: NoSplash.splashFactory,
          highlightColor: colors.secondarySurface,
          child: Container(
            constraints: const BoxConstraints(minHeight: minHeight),
            // A coloured frame appears nowhere else in the product. That is
            // what makes it read as "this money is different" rather than as
            // decoration.
            decoration: visualClass.isFramed && !isArchived
                ? BoxDecoration(
                    border: Border.all(
                      color: colors.protectedMoney,
                      width: AppTheme.regionRuleWidth,
                    ),
                  )
                : null,
            // A Stack, not an IntrinsicHeight row. IntrinsicHeight asks its
            // children how tall they want to be at their *minimum* width, and
            // the amount is a Wrap — which answers "one line per element",
            // making every tile as tall as its most pessimistic wrap. The edge
            // gets its full height from Positioned.fill instead, which costs
            // nothing and cannot lie.
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: 0,
                  child: _LeadingEdge(
                    treatment: visualClass.edge,
                    color: roleColor,
                    isArchived: isArchived,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: edgeWidth + AppTheme.space12,
                    end: AppTheme.space12,
                    top: AppTheme.space12,
                    bottom: AppTheme.space12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        visualClass.icon,
                        size: 20,
                        color: isArchived
                            ? colors.disabled
                            : colors.primaryText,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      // The name gets the larger share: a wrapped account name
                      // is readable, a wrapped amount is not.
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: roles.cardTitle.copyWith(
                                color: isArchived ? colors.disabled : null,
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(subtitle, style: roles.supportingMeta),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Flexible(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Held money carries the lock and no sign; a
                            // spendable balance is a stated figure, not a
                            // movement, so it carries neither.
                            FinancialAmountText(
                              minorUnits: minorUnits,
                              currencyCode: currencyCode,
                              tone: isArchived
                                  ? FinancialAmountTone.muted
                                  : tone,
                              direction: visualClass.isHeld
                                  ? FinancialAmountDirection.held
                                  : FinancialAmountDirection.none,
                            ),
                            if (trailingBadge case final Widget badge) ...[
                              const SizedBox(height: AppTheme.space4),
                              badge,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingEdge extends StatelessWidget {
  const _LeadingEdge({
    required this.treatment,
    required this.color,
    required this.isArchived,
  });

  final EdgeTreatment treatment;
  final Color color;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return SizedBox(
      width: AccountListTile.edgeWidth,
      child: CustomPaint(
        size: const Size(AccountListTile.edgeWidth, double.infinity),
        painter: _EdgePainter(
          treatment: treatment,
          // Archived is outline only — history retained, read only.
          color: isArchived ? colors.disabled : color,
          isOutlineOnly: isArchived,
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.treatment,
    required this.color,
    required this.isOutlineOnly,
  });

  final EdgeTreatment treatment;
  final Color color;
  final bool isOutlineOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (isOutlineOnly) {
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      return;
    }

    switch (treatment) {
      case EdgeTreatment.solid:
        canvas.drawRect(rect, Paint()..color = color);
      case EdgeTreatment.hatched:
        paintHatch(canvas, rect, color);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.treatment != treatment ||
      old.color != color ||
      old.isOutlineOnly != isOutlineOnly;
}
