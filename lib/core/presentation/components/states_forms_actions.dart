import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

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

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    super.key,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(message, style: roles.body, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.space20),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
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

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({required this.child, super.key});

  final Widget child;

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
          child: child,
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
