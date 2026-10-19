import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../data/user_repository.dart';
import '../../models/organization.dart';
import '../../models/user.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/user_avatar.dart';
import 'organization_providers.dart';

class OrganizationMembersScreen extends ConsumerStatefulWidget {
  const OrganizationMembersScreen({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState
    extends ConsumerState<OrganizationMembersScreen> {
  String _filter = '';

  OrganizationMembersNotifier get _notifier =>
      ref.read(organizationMembersProvider(widget.organizationId).notifier);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _editMember(OrgMember member) async {
    var role = member.role;
    final action = await showDialog<String>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Edit Member'),
                  content: DropdownButtonFormField<OrgRole>(
                    value: role,
                    items: [
                      for (final r in const [OrgRole.member, OrgRole.admin])
                        DropdownMenuItem(value: r, child: Text(r.name)),
                    ],
                    onChanged:
                        (value) => setDialogState(() => role = value ?? role),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'update'),
                      child: const Text('Update Role'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'remove'),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          ),
    );

    if (action == 'update') {
      await _run(() => _notifier.changeRole(member.userId, role));
    } else if (action == 'remove') {
      await _run(() => _notifier.remove(member.userId));
    }
  }

  Future<void> _addMember(Set<int> existing) async {
    final picked = await showDialog<({User user, OrgRole role})>(
      context: context,
      builder: (_) => _AddMemberDialog(existingIds: existing),
    );
    if (picked != null) {
      await _run(() => _notifier.add(picked.user.id, picked.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(
      organizationMembersProvider(widget.organizationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Organization Members')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          organizationMembersProvider(widget.organizationId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (all) {
          final visible =
              all
                  .where((m) => m.role != OrgRole.owner)
                  .where(
                    (m) => (m.user?.name ?? '').toLowerCase().contains(_filter),
                  )
                  .toList()
                ..sort((a, b) => a.role.index.compareTo(b.role.index));
          final existing = {for (final m in all) m.userId};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ShadowButton(
                    icon: Icons.person_add,
                    label: 'Add Member',
                    onTap: () => _addMember(existing),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search members',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (v) => setState(() => _filter = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    visible.isEmpty
                        ? const Center(child: Text('No members yet'))
                        : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (_, i) {
                            final member = visible[i];
                            final user = member.user;
                            return ListTile(
                              leading: UserAvatar(
                                name: user?.name ?? '?',
                                imageUrl: user?.profilePic,
                                backgroundColor: Colors.grey,
                              ),
                              title: Text(user?.name ?? 'Unknown'),
                              subtitle: Text(member.role.name),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.black45,
                                ),
                                onPressed: () => _editMember(member),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddMemberDialog extends ConsumerStatefulWidget {
  const _AddMemberDialog({required this.existingIds});

  final Set<int> existingIds;

  @override
  ConsumerState<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<_AddMemberDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<User> _results = const [];
  OrgRole _role = OrgRole.member;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        if (mounted) setState(() => _results = const []);
        return;
      }
      try {
        final users = await ref
            .read(userRepositoryProvider)
            .search(query.trim());
        if (mounted) {
          setState(() {
            _results =
                users.where((u) => !widget.existingIds.contains(u.id)).toList();
          });
        }
      } catch (e) {
        if (mounted) showErrorSnack(context, e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search user by name',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrgRole>(
                value: _role,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final r in const [OrgRole.member, OrgRole.admin])
                    DropdownMenuItem(value: r, child: Text(r.name)),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: 12),
              if (_results.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final user = _results[i];
                      return ListTile(
                        title: Text(user.name),
                        onTap:
                            () => Navigator.pop(context, (
                              user: user,
                              role: _role,
                            )),
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
