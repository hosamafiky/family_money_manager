import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _householdId = 'household-v1';

/// Screen listing household members grouped by role.
///
/// Shows primary user, spouse (if present), and children.
/// Provides actions to add spouse, add child, rename, and archive members.
class HouseholdMembersScreen extends ConsumerWidget {
  const HouseholdMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(householdMembersProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle), centerTitle: false),
      body: membersAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (result) => switch (result) {
          AppOk(:final value) => _MembersList(members: value),
          _ => Center(child: Text(l10n.errorGeneric)),
        },
      ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  const _MembersList({required this.members});

  final List<HouseholdMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final primaryUsers = members
        .where((m) => m.role == MemberRole.primaryUser)
        .toList();
    final spouses = members.where((m) => m.role == MemberRole.spouse).toList();
    final children = members.where((m) => m.role == MemberRole.child).toList();
    final hasSpouse = spouses.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Primary user section
        _SectionHeader(label: l10n.memberPrimaryUser),
        ...primaryUsers.map((m) => _MemberTile(member: m)),
        const SizedBox(height: 12),
        // Spouse section
        _SectionHeader(label: l10n.memberSpouse),
        ...spouses.map((m) => _MemberTile(member: m)),
        if (!hasSpouse)
          _AddButton(
            label: l10n.memberAddSpouse,
            onPressed: () =>
                _showAddMemberDialog(context, ref, l10n, MemberRole.spouse),
          ),
        // V1 note about spouse login
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.memberSpouseLoginNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Children section
        _SectionHeader(label: l10n.memberChild),
        ...children.map((m) => _MemberTile(member: m)),
        _AddButton(
          label: l10n.memberAddChild,
          onPressed: () =>
              _showAddMemberDialog(context, ref, l10n, MemberRole.child),
        ),
      ],
    );
  }

  Future<void> _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    MemberRole role,
  ) async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          role == MemberRole.spouse
              ? l10n.memberAddSpouse
              : l10n.memberAddChild,
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.memberName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, nameCtrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final useCase = ref.read(addMemberUseCaseProvider);
    final addResult = await useCase.execute(
      householdId: _householdId,
      displayName: result.trim(),
      role: role,
    );

    if (!context.mounted) return;

    switch (addResult) {
      case AppOk():
        ref.invalidate(householdMembersProvider(_householdId));
      case AppDuplicateConflict():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorSpouseDuplicate)));
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(member.displayName),
        subtitle: member.isArchived ? Text(l10n.archivedLabel) : null,
        trailing: member.role != MemberRole.primaryUser && !member.isArchived
            ? PopupMenuButton<_MemberAction>(
                onSelected: (action) => _onAction(context, ref, l10n, action),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: _MemberAction.rename,
                    child: Text(l10n.memberRename),
                  ),
                  PopupMenuItem(
                    value: _MemberAction.archive,
                    child: Text(l10n.memberArchive),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    _MemberAction action,
  ) async {
    switch (action) {
      case _MemberAction.rename:
        await _showRenameDialog(context, ref, l10n);
      case _MemberAction.archive:
        await _confirmArchive(context, ref, l10n);
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final nameCtrl = TextEditingController(text: member.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.memberRename),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.memberName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final useCase = ref.read(renameMemberUseCaseProvider);
    await useCase.execute(
      memberId: member.id,
      householdId: _householdId,
      displayName: result.trim(),
    );

    if (!context.mounted) return;
    ref.invalidate(householdMembersProvider(_householdId));
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.memberArchive),
        content: Text(member.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final useCase = ref.read(archiveMemberUseCaseProvider);
    final result = await useCase.execute(
      memberId: member.id,
      householdId: _householdId,
    );

    if (!context.mounted) return;

    switch (result) {
      case AppOk():
        ref.invalidate(householdMembersProvider(_householdId));
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_outlined),
      label: Text(label),
    );
  }
}

enum _MemberAction { rename, archive }
