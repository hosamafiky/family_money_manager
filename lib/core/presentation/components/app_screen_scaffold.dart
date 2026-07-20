import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Standard screen chrome: optional top bar, body, bottom bar.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null && actions == null && leading == null
          ? null
          : AppBar(title: title, actions: actions, leading: leading),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar ?? bottomNavigationBar,
    );
  }
}

/// Thin wrapper for titled app bars using semantic title style.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    super.key,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: context.textRoles.screenTitle),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

/// Constrains form/list content for wide layouts.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({
    required this.child,
    super.key,
    this.maxWidth = AppTheme.formContentMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Padding(
      padding:
          padding ??
          const EdgeInsets.only(top: AppTheme.space20, bottom: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: roles.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(subtitle!, style: roles.supportingMeta),
                ],
              ],
            ),
          ),
          if (trailing case final Widget t) t,
        ],
      ),
    );
  }
}
