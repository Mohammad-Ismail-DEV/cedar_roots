import 'package:cedar_roots/screens/create_event.dart';
import 'package:cedar_roots/screens/event_details.dart';
import 'package:cedar_roots/screens/manage_organization.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrganizationScreen extends StatefulWidget {
  final int organizationId;

  const OrganizationScreen({Key? key, required this.organizationId})
    : super(key: key);

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  Map<String, dynamic>? organization;
  bool _isLoading = true;
  int? _userId;
  String? _userRole; // "owner", "admin", "member"
  bool _isFollowing = false;

  final api = ApiServices();

  @override
  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return;

    if (!mounted) return;
    setState(() => _userId = id);
    await _fetchOrganization();
    await _fetchUserRole();
  }

  Future<void> _fetchOrganization() async {
    try {
      final response = await api.fetchOrganizationById(widget.organizationId);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? role;
        bool following = false;

        if (data['OrganizationMembers'] != null) {
          final match = (data['OrganizationMembers'] as List).firstWhere(
            (m) => m['user_id'] == _userId,
            orElse: () => null,
          );
          if (match != null) role = match['role'];
        }

        if (data['OrganizationFollowers'] != null) {
          following = (data['OrganizationFollowers'] as List).any(
            (f) => f['user_id'] == _userId,
          );
        }

        if (!mounted) return;
        setState(() {
          organization = data;
          _userRole = role;
          _isFollowing = following;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load organization');
      }
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_userId == null || !mounted) return;

    try {
      final response =
          _isFollowing
              ? await api.unfollowOrganization(widget.organizationId)
              : await api.followOrganization(widget.organizationId);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          mounted) {
        await _fetchOrganization();
      }
    } catch (e) {
      print('❌ Error toggling follow: $e');
    }
  }

  Future<void> _fetchUserRole() async {
    if (_userId == null) return;

    try {
      final res = await api.getOrganizationMembers(widget.organizationId);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final members = jsonDecode(res.body);
        final match = members.firstWhere(
          (m) => m['user_id'] == _userId,
          orElse: () => null,
        );

        if (match != null && mounted) {
          setState(() => _userRole = match['role']);
        }
      }
    } catch (e) {
      print("Failed to fetch user role: $e");
    }
  }

  void _navigateToCreateEvent() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateEventScreen(organizationId: widget.organizationId),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    return InkWell(
      onTap: () async {
        // Assuming you're using SharedPreferences to store the current user ID
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id') ?? 0;

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => EventDetailsScreen(eventId: event['id'], userId: userId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'] ?? 'Untitled Event',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (event['date_time'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      'MMM d, yyyy • h:mm a',
                    ).format(DateTime.parse(event['date_time'])),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              event['location'] ?? 'No location',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Organization Profile",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              )
              : organization == null
              ? const Center(
                child: Text(
                  'Organization not found.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          organization!['logo'] != null &&
                                  organization!['logo'] != ''
                              ? NetworkImage(organization!['logo'])
                              : null,
                      child:
                          organization!['logo'] == null ||
                                  organization!['logo'] == ''
                              ? const Icon(
                                Icons.apartment,
                                size: 40,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      organization!['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      organization!['website'] ?? '',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_userRole == 'owner')
                                IconButton(
                                  onPressed: _navigateToManageOrganization,
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.black54,
                                  ),
                                  tooltip: 'Manage',
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            organization!['description'] ??
                                'No description available.',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          if (organization!['location'] != null &&
                              organization!['location'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.orangeAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    organization!['location'],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12), // Smaller gap than before
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            Icons.people,
                            'Followers',
                            organization!['OrganizationFollowers'].length ?? 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            Icons.event,
                            'Events',
                            organization!['Events'].length ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_userRole == null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _buildShadowButton(
                          icon: _isFollowing ? Icons.remove : Icons.add,
                          label:
                              _isFollowing
                                  ? "Unfollow Organization"
                                  : "Follow Organization",
                          onTap: _toggleFollow,
                          textColor: _isFollowing ? Colors.red : Colors.green,
                        ),
                      )
                    else if (_userRole != 'member')
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _buildShadowButton(
                          icon: Icons.add,
                          label: "Create Event",
                          onTap: _navigateToCreateEvent,
                          textColor: Colors.green,
                        ),
                      ),

                    const SizedBox(height: 24),
                    if (organization!['Events'] != null &&
                        organization!['Events'].isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Events",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...organization!['Events'].map<Widget>((event) {
                            return _buildEventCard(event);
                          }).toList(),
                        ],
                      )
                    else
                      const Text(
                        "No events yet.",
                        style: TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
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

  void _navigateToManageOrganization() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                ManageOrganizationScreen(organizationId: widget.organizationId),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // pop back with refresh flag
    }
  }

  Widget _buildStatBox(IconData icon, String label, int value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
