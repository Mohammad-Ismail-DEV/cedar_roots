import 'package:cedar_roots/screens/create_organization.dart';
import 'package:cedar_roots/screens/organization.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class OrganizationsScreen extends StatefulWidget {
  final int userId;

  const OrganizationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  List<dynamic> _organizations = [];
  bool _isLoading = true;
  final api = ApiServices();

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  Widget buildShadowButton({
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchOrganizations() async {
    try {
      final response = await api.fetchUserOrganizations(widget.userId);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          _organizations = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch organizations');
      }
    } catch (e) {
      print('Error fetching organizations: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCreateOrganization() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrganizationScreen()),
    );

    // Optional: Refresh organizations if one was created
    if (result == true && mounted) {
      _fetchOrganizations();
    }
  }

  void _navigateToOrganization(int organizationId) async {
  if (!mounted) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OrganizationScreen(organizationId: organizationId),
    ),
  );

  if (result == true && mounted) {
    _fetchOrganizations(); // Refresh list if an org was deleted
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "My Organizations",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: buildShadowButton(
            label: "Create Organization",
            onTap: _navigateToCreateOrganization,
            textColor: Colors.green,
          ),
        ),
      ),

      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              )
              : _organizations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.orangeAccent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No Organizations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "You haven't created or joined any organizations yet.",
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _organizations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final org = _organizations[index];
                  return InkWell(
                    onTap: () {
                      if (!mounted) return;
                      _navigateToOrganization(org['id']);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                org['logo'] != null && org['logo'] != ''
                                    ? NetworkImage(org['logo'])
                                    : null,
                            child:
                                org['logo'] == null || org['logo'] == ''
                                    ? const Icon(
                                      Icons.apartment,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              org['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
