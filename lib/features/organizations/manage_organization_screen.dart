import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../shell/app_routes.dart';
import 'organization_providers.dart';

/// Owner-only settings: members, edit details, delete.
class ManageOrganizationScreen extends ConsumerWidget {
  const ManageOrganizationScreen({super.key, required this.organizationId});

  final int organizationId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(
      context,
      title: 'Delete Organization',
      message:
          'Are you sure you want to delete this organization? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(organizationProvider(organizationId).notifier).delete();
      if (!context.mounted) return;
      Navigator.pop(context, true);
      showSnack(context, 'Organization deleted');
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Organization',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ManageTile(
            icon: Icons.group,
            title: 'Manage Members',
            onTap:
                () => Navigator.push(
                  context,
                  AppRoutes.organizationMembers(organizationId),
                ),
          ),
          _ManageTile(
            icon: Icons.edit,
            title: 'Edit Information',
            onTap:
                () => Navigator.push(
                  context,
                  AppRoutes.organizationForm(organizationId: organizationId),
                ),
          ),
          _ManageTile(
            icon: Icons.delete_outline,
            title: 'Delete Organization',
            color: Colors.red,
            onTap: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.black,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
