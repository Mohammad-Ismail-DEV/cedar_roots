import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:async'; // at the top

class OrganizationMembersScreen extends StatefulWidget {
  final int organizationId;

  const OrganizationMembersScreen({super.key, required this.organizationId});

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState extends State<OrganizationMembersScreen> {
  List<dynamic> members = [];
  bool _isLoading = true;
  final _api = ApiServices();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _memberSearch = '';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await _api.getOrganizationMembers(widget.organizationId);
    if (!mounted) return;

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        members = data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showMessage('Failed to load members');
    }
  }

  Future<void> _removeMember(int userId) async {
    final res = await _api.removeOrganizationMember(
      userId: userId,
      organizationId: widget.organizationId,
    );
    if (!mounted) return;

    if (res.statusCode == 200) {
      _fetchMembers();
    } else {
      _showMessage('Failed to remove member');
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    final res = await _api.updateOrganizationMemberRole(
      userId: userId,
      organizationId: widget.organizationId,
      role: newRole,
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      await _fetchMembers(); // Auto-refresh list
    } else {
      _showMessage('Failed to update role');
    }
  }

  Future<void> _addMember(int userId, String role) async {
    final res = await _api.addOrganizationMember(
      userId: userId,
      organizationId: widget.organizationId,
      role: role,
    );
    if (!mounted) return;

    if (res.statusCode == 200) {
      _fetchMembers();
    } else {
      final error = jsonDecode(res.body)['error'] ?? 'Failed to add member';
      _showMessage(error);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditMemberDialog(Map<String, dynamic> member) {
    String role = member['role'];

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Member'),
            content: DropdownButtonFormField<String>(
              value: role,
              items:
                  ['member', 'admin']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
              onChanged: (value) {
                if (value != null) role = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _changeRole(member['user_id'], role);
                },
                child: const Text('Update Role'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeMember(member['user_id']);
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddMemberDialog() {
    String selectedRole = 'member';
    List<dynamic> results = [];
    int? selectedUserId;
    _searchController.clear();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 100,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add Member',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search user by name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (query) {
                          if (_searchDebounce?.isActive ?? false) {
                            _searchDebounce!.cancel();
                          }

                          _searchDebounce = Timer(
                            const Duration(milliseconds: 500),
                            () async {
                              if (!mounted) return;

                              if (query.trim().isEmpty) {
                                setDialogState(() => results = []);
                                return;
                              }

                              final res = await _api.searchUsersByName(query);
                              if (res.statusCode == 200 && mounted) {
                                final data =
                                    jsonDecode(res.body) as List<dynamic>;

                                final currentIds =
                                    members.map((m) => m['user_id']).toSet();
                                final filtered =
                                    data
                                        .where(
                                          (user) =>
                                              !currentIds.contains(user['id']),
                                        )
                                        .toList();

                                setDialogState(() => results = filtered);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ['member', 'admin']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setDialogState(
                              () => selectedRole = val ?? 'member',
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (results.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: results.length,
                            itemBuilder: (_, index) {
                              final user = results[index];
                              return ListTile(
                                title: Text(user['name']),
                                onTap: () {
                                  selectedUserId = user['id'];
                                  Navigator.pop(context);
                                  _addMember(selectedUserId!, selectedRole);
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShadowButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMembers =
        members.where((m) => m['role'] != 'owner').toList()..sort((a, b) {
          const rolePriority = {'admin': 0, 'member': 1};
          return rolePriority[a['role']]!.compareTo(rolePriority[b['role']]!);
        });

    return Scaffold(
      appBar: AppBar(title: const Text("Organization Members")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _buildShadowButton(
                        icon: Icons.person_add,
                        label: "Add Member",
                        onTap: _showAddMemberDialog,
                        textColor: Colors.green,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search members',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(
                                () => _memberSearch = value.toLowerCase(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              visibleMembers.isEmpty
                                  ? const Center(child: Text('No members yet'))
                                  : ListView.builder(
                                    itemCount: visibleMembers.length,
                                    itemBuilder: (_, i) {
                                      final member = visibleMembers[i];
                                      final user = member['User'];
                                      final name =
                                          user['name'].toString().toLowerCase();

                                      if (_memberSearch.isNotEmpty &&
                                          !name.contains(_memberSearch)) {
                                        return const SizedBox.shrink();
                                      }

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            user['name'][0].toUpperCase(),
                                          ),
                                        ),
                                        title: Text(user['name']),
                                        subtitle: Text(member['role']),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.black45,
                                          ),
                                          onPressed:
                                              () => _showEditMemberDialog({
                                                'user_id': user['id'],
                                                'name': user['name'],
                                                'role': member['role'],
                                              }),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
