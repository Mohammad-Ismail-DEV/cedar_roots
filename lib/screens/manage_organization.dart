import 'package:cedar_roots/screens/edit_organization.dart';
import 'package:cedar_roots/screens/organization_members.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ManageOrganizationScreen extends StatelessWidget {
  final int organizationId;

  const ManageOrganizationScreen({Key? key, required this.organizationId})
    : super(key: key);

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Organization'),
            content: const Text(
              'Are you sure you want to delete this organization? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final api = ApiServices();
      final res = await api.deleteOrganization(organizationId);
      if (res.statusCode == 200) {
        if (!context.mounted) return;
        Navigator.pop(context, true); // pass result to OrganizationScreen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Organization deleted')));
      } else {
        if (!context.mounted) return;
        final error = jsonDecode(res.body)['error'] ?? 'Failed to delete';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Manage Organization",
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
          _buildManageTile(
            icon: Icons.group,
            title: "Manage Members",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => OrganizationMembersScreen(
                        organizationId: organizationId,
                      ),
                ),
              );
            },
          ),
          _buildManageTile(
            icon: Icons.edit,
            title: "Edit Information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EditOrganizationScreen(
                        organizationId: organizationId,
                      ),
                ),
              );
            },
          ),
          _buildManageTile(
            icon: Icons.delete_outline,
            title: "Delete Organization",
            textColor: Colors.red,
            onTap: () {
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManageTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
  }) {
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
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
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
