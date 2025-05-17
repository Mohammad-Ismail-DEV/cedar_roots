import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final int eventId;
  final int userId;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
    required this.userId,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Map<String, dynamic>? event;
  List<dynamic> announcements = [];
  List<dynamic> participants = [];
  List<dynamic> orgMembers = [];
  bool isParticipant = false;
  bool isOrgMember = false;
  bool isOrgAdmin = false;
  final TextEditingController _announcementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final eventRes = await http.get(
      Uri.parse('http://13.50.2.82:3000/events/${widget.eventId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final participantsRes = await http.get(
      Uri.parse('http://13.50.2.82:3000/events/${widget.eventId}/participants'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final announcementsRes = await http.get(
      Uri.parse('http://13.50.2.82:3000/announcements/${widget.eventId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (eventRes.statusCode == 200 &&
        participantsRes.statusCode == 200 &&
        announcementsRes.statusCode == 200) {
      final e = json.decode(eventRes.body);
      final pList = json.decode(participantsRes.body);
      final aList = json.decode(announcementsRes.body);

      final orgId = e['organization_id'];
      final orgRes = await http.get(
        Uri.parse('http://13.50.2.82:3000/organization_members/$orgId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (orgRes.statusCode == 200) {
        final orgList = json.decode(orgRes.body);
        final userMembership = orgList.firstWhere(
          (m) => m['user_id'] == widget.userId,
          orElse: () => null,
        );

        final userParticipant = pList.firstWhere(
          (p) => p['user_id'] == widget.userId,
          orElse: () => null,
        );

        setState(() {
          event = e;
          announcements = aList;
          participants = pList;
          orgMembers = orgList;
          isParticipant = userParticipant != null;
          isOrgMember = userMembership != null;
          isOrgAdmin =
              userMembership != null &&
              (userMembership['role'] == 'admin' ||
                  userMembership['role'] == 'owner');
        });
      }
    }
  }

  Future<void> _joinEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final res = await http.post(
      Uri.parse('http://13.50.2.82:3000/events/${widget.eventId}/join'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      _fetchEventDetails();
    }
  }

  Future<void> _leaveEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final res = await http.delete(
      Uri.parse(
        'http://13.50.2.82:3000/events/${widget.eventId}/leave/${widget.userId}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      _fetchEventDetails();
    }
  }

  Future<void> _postAnnouncement() async {
    final message = _announcementController.text.trim();
    if (message.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final res = await http.post(
      Uri.parse('http://13.50.2.82:3000/announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'event_id': widget.eventId, 'message': message}),
    );

    if (res.statusCode == 200) {
      _announcementController.clear();
      _fetchEventDetails();
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return 'Unknown time';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;

    return DateFormat('MMMM d, y • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final org = event!['Organization'] ?? {};
    final orgName = org['name'] ?? 'Unknown';
    final orgLogo = org['logo'];

    return Scaffold(
      appBar: AppBar(title: const Text("Event Details")),
      body: RefreshIndicator(
        onRefresh: _fetchEventDetails,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      orgLogo != null ? NetworkImage(orgLogo) : null,
                  child: orgLogo == null ? Text(orgName[0]) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  orgName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event!['title'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event!['description'] ?? ''),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(event!['date_time']),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (event!['location'] != null)
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 4),
                  Text(event!['location']),
                ],
              ),
            const SizedBox(height: 16),

            // Join/Leave button logic
            if (!isOrgMember && !isParticipant)
              ElevatedButton(
                onPressed: _joinEvent,
                child: const Text('Join Event'),
              ),
            if (!isOrgMember && isParticipant)
              ElevatedButton(
                onPressed: _leaveEvent,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Leave Event'),
              ),

            const SizedBox(height: 24),
            const Text(
              "Announcements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isOrgAdmin) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _announcementController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Write an announcement...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _postAnnouncement,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...announcements.map(
              (a) => ListTile(
                title: Text(a['message']),
                subtitle: Text(_formatDateTime(a['created_at'])),
                leading: const Icon(Icons.campaign_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
