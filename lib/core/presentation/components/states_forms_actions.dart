import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// A centred spinner with an optional message.
///
/// Retained deliberately. [AppSkeletonList] is the redesign's loading state
/// for anything list-shaped, but swapping it in is a per-screen change: these
/// screens' tests currently rely on the spinner's ticker to drive
/// `pumpAndSettle` far enough for their provider futures to resolve, so the
/// swap belongs with each screen's own phase, where those tests are rewritten
/// against the real provider anyway. Changing it here would break four screens'
/// error-state tests for reasons unrelated to what they assert.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppTheme.space16),
                Text(message!, style: context.textRoles.supportingMeta),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading, drawn as the shape of the content that is coming.
///
/// A spinner says "something is happening somewhere"; a skeleton says "a list
/// of rows is arriving, and it will look like this". Because the geometry
/// already matches the real row, the cross-fade to content moves nothing —
/// which is why the design forbids a spinner in a list.
///
/// It deliberately does not shimmer. A pulsing placeholder is motion that
/// clarifies nothing, and the design admits motion only where it explains a
/// state change.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.message,
    this.rowCount = 4,
    this.rowHeight = 64,
  });

  /// Announced to screen readers. Never the only signal — the skeleton is.
  final String? message;

  final int rowCount;

  /// Match this to the real row it stands in for.
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return Semantics(
      label: message,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rowCount; i++)
              _SkeletonRow(height: rowHeight, colors: colors),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.height, required this.colors});

  final double height;
  final AppFinancialColors colors;

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height) =>
        Container(width: width, height: height, color: colors.secondarySurface);

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          // Stands in for the leading edge of a real account row.
          block(AppTheme.space4, double.infinity),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                block(140, 14),
                const SizedBox(height: AppTheme.space8),
                block(90, 10),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          block(72, 16),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final colors = context.financialColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.secondaryText),
            const SizedBox(height: AppTheme.space16),
            Text(title, style: roles.sectionTitle, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                message!,
                style: roles.supportingMeta,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.space20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// An error that states what happened to the data before it offers a retry.
///
/// In a ledger the user's first question after a failure is never "why" — it
/// is "did that corrupt anything". [dataStatus] answers it, and defaults to
/// saying nothing was written, which is true of every read path.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    super.key,
    this.dataStatus,
    this.errorCode,
    this.onRetry,
    this.retryLabel,
  });

  /// What went wrong, localised.
  final String message;

  /// What it did to the household's data, localised. Falls back to
  /// `errorLedgerUnchanged`.
  final String? dataStatus;

  /// A short technical code, shown so a support conversation has something to
  /// quote. Never localised — it is an identifier, not copy.
  final String? errorCode;

  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = context.textRoles;
    final colors = context.financialColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: colors.warning),
            const SizedBox(height: AppTheme.space16),
            Text(message, style: roles.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space8),
            Text(
              dataStatus ?? l10n.errorLedgerUnchanged,
              style: roles.body.copyWith(color: colors.neutralInfo),
              textAlign: TextAlign.center,
            ),
            if (errorCode case final String code) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                l10n.errorCodeLabel(code),
                style: roles.supportingMeta,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry case final VoidCallback retry) ...[
              const SizedBox(height: AppTheme.space20),
              OutlinedButton(
                onPressed: retry,
                child: Text(retryLabel ?? l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppInlineNotice extends StatelessWidget {
  const AppInlineNotice({
    required this.message,
    super.key,
    this.tone = AppNoticeTone.info,
    this.icon,
  });

  final String message;
  final AppNoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final Color fg = switch (tone) {
      AppNoticeTone.info => colors.neutralInfo,
      AppNoticeTone.warning => colors.warning,
      AppNoticeTone.error => Theme.of(context).colorScheme.error,
      AppNoticeTone.success => colors.success,
    };
    final IconData resolvedIcon =
        icon ??
        switch (tone) {
          AppNoticeTone.info => Icons.info_outline,
          AppNoticeTone.warning => Icons.warning_amber_outlined,
          AppNoticeTone.error => Icons.error_outline,
          AppNoticeTone.success => Icons.check_circle_outline,
        };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(resolvedIcon, color: fg, size: 20),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                message,
                style: context.textRoles.body.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AppNoticeTone { info, warning, error, success }

class AppFormSection extends StatelessWidget {
  const AppFormSection({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: roles.sectionTitle),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.space4),
            Text(subtitle!, style: roles.supportingMeta),
          ],
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }
}

class AppReviewSection extends StatelessWidget {
  const AppReviewSection({required this.title, required this.rows, super.key});

  final String title;
  final List<AppReviewRowData> rows;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final colors = context.financialColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: roles.sectionTitle),
        const SizedBox(height: AppTheme.space12),
        Container(
          decoration: BoxDecoration(
            color: colors.secondarySurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(rows[i].label, style: roles.supportingMeta),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Flexible(
                        child: Text(
                          rows[i].value,
                          style: roles.body,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppReviewRowData {
  const AppReviewRowData({required this.label, required this.value});
  final String label;
  final String value;
}

/// A pinned action bar with a permanent consequence line beneath it.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    required this.child,
    super.key,
    this.consequenceLabel,
  });

  final Widget child;

  /// What saving will do, localised — permanent rather than conditional.
  ///
  /// It is how the app teaches append-only *before* the user learns it by
  /// looking for a delete button that does not exist.
  final String? consequenceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return Material(
      elevation: 0,
      color: colors.mainSurface,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space12,
            AppTheme.space16,
            AppTheme.space12,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              if (consequenceLabel case final String label) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  label,
                  style: context.textRoles.supportingMeta.copyWith(
                    color: colors.neutralInfo,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class DestructiveActionButton extends StatelessWidget {
  const DestructiveActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Progressive disclosure for secondary form fields (notes, advanced options).
class AppExpandableDetails extends StatelessWidget {
  const AppExpandableDetails({
    required this.title,
    required this.child,
    super.key,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsetsDirectional.only(
          bottom: AppTheme.space12,
        ),
        title: Text(title, style: roles.sectionTitle),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: roles.supportingMeta),
        children: [child],
      ),
    );
  }
}

/// Shared confirmation dialog for sensitive / destructive actions.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelLabel ?? MaterialLocalizations.of(ctx).cancelButtonLabel,
            ),
          ),
          if (isDestructive)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
        ],
      );
    },
  );
  return result ?? false;
}
