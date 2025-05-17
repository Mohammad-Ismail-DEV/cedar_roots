import 'dart:async';
import 'dart:convert';
import 'package:cedar_roots/screens/create_post.dart';
import 'package:cedar_roots/screens/organization.dart';
import 'package:cedar_roots/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cedar_roots/components/comment_section.dart';
import 'package:cedar_roots/components/user_post.dart';
import 'package:cedar_roots/screens/chats.dart';
import 'package:cedar_roots/screens/event_details.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:cedar_roots/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  bool _initializedFCM = false;
  List<Map<String, dynamic>> _feed = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = true;
  bool _showSearchOverlay = false;
  final api = ApiServices();
  int? _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initFirebase();
    _fetchFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
      if (_isLoggedIn && !_initializedFCM) {
        _initializedFCM = true;
        FirebaseNotificationService().initialize();
      }
    });
  }

  Future<void> _initFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("isLoggedIn") == true) {
      FirebaseNotificationService().initialize();
    }
  }

  Future<void> _fetchFeed() async {
    setState(() => _loading = true);

    try {
      await api.init();
      await api.init();
      final userId = _currentUserId; // Use from prefs or auth
      final posts = await api.fetchPosts(userId);
      final events = await api.fetchEvents(userId);

      final allItems = [
        ...posts.map((p) => Map<String, dynamic>.from(p)..['type'] = 'post'),
        ...events.map((e) => Map<String, dynamic>.from(e)..['type'] = 'event'),
      ];

      allItems.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _feed = allItems;
        _searchResults = [];
        _loading = false;
      });
    } catch (e) {
      print('❌ Error fetching feed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || !_isLoggedIn) {
      setState(() => _showSearchOverlay = false);
      return;
    }

    try {
      await api.init();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('http://13.50.2.82:3000/search?q=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        final items = <Map<String, dynamic>>[
          ...(result['users'] as List).map((u) => {...u, 'type': 'user'}),
          ...(result['organizations'] as List).map(
            (o) => {...o, 'type': 'org'},
          ),
          ...(result['events'] as List).map((e) => {...e, 'type': 'event'}),
          ...(result['posts'] as List).map((p) => {...p, 'type': 'post'}),
        ];

        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(items);
          _showSearchOverlay = true;
        });
      }
    } catch (e) {
      print("❌ Search failed: $e");
    }
  }

  Widget _buildSearchOverlay() {
    if (!_showSearchOverlay) return const SizedBox.shrink();

    final users = _searchResults.where((e) => e['type'] == 'user').toList();
    final orgs = _searchResults.where((e) => e['type'] == 'org').toList();
    final events = _searchResults.where((e) => e['type'] == 'event').toList();
    final posts = _searchResults.where((e) => e['type'] == 'post').toList();

    final isEmpty =
        users.isEmpty && orgs.isEmpty && events.isEmpty && posts.isEmpty;

    return Positioned(
      left: 12,
      right: 12,
      top: 72,
      child: Card(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        "No results found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (users.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Users",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          ...users.map(
                            (u) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    u['profile_pic'] != null
                                        ? NetworkImage(u['profile_pic'])
                                        : null,
                                child:
                                    u['profile_pic'] == null
                                        ? Text(u['name'][0])
                                        : null,
                              ),
                              title: Text(u['name']),
                              onTap: () async {
                                // Refocus the search input
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());

                                // Optional: clear input and results
                                //_searchController.clear();
                                //setState(() {
                                //  _searchResults = [];
                                //  _showSearchOverlay = false;
                                //});

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProfileScreen(userId: u['id']),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (orgs.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Organizations",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          ...orgs.map(
                            (o) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    o['logo'] != null
                                        ? NetworkImage(o['logo'])
                                        : null,
                                child:
                                    o['logo'] == null
                                        ? Text(o['name'][0])
                                        : null,
                              ),
                              title: Text(o['name']),
                              onTap: () async {
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());

                                // Optional clear
                                //_searchController.clear();
                                //setState(() {
                                //  _searchResults = [];
                                //  _showSearchOverlay = false;
                                //});

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => OrganizationScreen(
                                          organizationId: o['id'],
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (events.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Events",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          ...events.map(
                            (e) => ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(e['title'] ?? ''),
                              onTap: () async {
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EventDetailsScreen(
                                          userId: _currentUserId ?? 0,
                                          eventId: e['id'],
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (posts.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Posts",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          ...posts.map(
                            (p) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    p['image_url'] != null
                                        ? NetworkImage(p['image_url'])
                                        : null,
                                child:
                                    p['image_url'] == null
                                        ? const Icon(Icons.post_add)
                                        : null,
                              ),
                              title: Text(
                                (p['content'] ?? '')
                                    .toString()
                                    .split('\n')
                                    .first,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());

                                // TODO: Navigate to PostDetailScreen(postId: p['id']);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  void handleComment(int postId) {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login to comment')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentSection(postId: postId),
    ).then((_) async {
      try {
        await api.init();
        final updatedPost = await api.fetchPostById(postId);
        final index = _feed.indexWhere((p) => p['id'] == postId);
        if (index != -1 && mounted) {
          setState(() {
            _feed[index] = {..._feed[index], ...updatedPost};
          });
        }
      } catch (e) {
        print("❌ Error fetching updated post: $e");
      }
    });
  }

  void handleLike(int postId, bool isLiked) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login to like')));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse("http://13.50.2.82:3000/posts/$postId/like"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'like': !isLiked}),
      );

      if (response.statusCode == 200) {
        final updatedPost = json.decode(response.body);
        final index = _feed.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          setState(() {
            _feed[index] = {..._feed[index], ...updatedPost};
          });
        }
      }
    } catch (e) {
      print("❌ Error toggling like: $e");
    }
  }

  void handleEdit(int postId) {
    final postToEdit = _feed.firstWhere((p) => p['id'] == postId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreatePostScreen(
              userId: _currentUserId!,
              existingPost: postToEdit,
            ),
      ),
    ).then((_) => _fetchFeed()); // Refresh feed after editing
  }

  void handleDelete(int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Post"),
            content: const Text("Are you sure you want to delete this post?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse("http://13.50.2.82:3000/posts/$postId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _feed.removeWhere((p) => p['id'] == postId);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _feed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cedar Roots'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatsScreen()),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  enabled: _isLoggedIn,
                  onChanged: _isLoggedIn ? _onSearchChanged : null,
                  decoration: InputDecoration(
                    filled: true, // <-- Add this
                    fillColor: Colors.white, // <-- Add this
                    hintText: _isLoggedIn ? 'Search' : 'Login to search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : list.isEmpty
                        ? const Center(child: Text("No results found."))
                        : RefreshIndicator(
                          onRefresh: _fetchFeed,
                          child: ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              final org = item['Organization'] ?? {};
                              final orgName = org['name'] ?? 'Unknown';
                              final orgLogo = org['logo'] ?? '';

                              return item['type'] == 'event'
                                  ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => EventDetailsScreen(
                                                userId: _currentUserId ?? 0,
                                                eventId: item['id'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      color: Colors.white,
                                      margin: const EdgeInsets.fromLTRB(
                                        12,
                                        1.5,
                                        12,
                                        1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Organization Info
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      orgLogo.isNotEmpty
                                                          ? NetworkImage(
                                                            orgLogo,
                                                          )
                                                          : null,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  child:
                                                      orgLogo.isEmpty
                                                          ? Text(
                                                            orgName[0]
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                          : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  orgName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Event Title
                                            Text(
                                              item['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),

                                            // Time
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat(
                                                    'MMM d, yyyy • hh:mm a',
                                                  ).format(
                                                    DateTime.tryParse(
                                                          item['date_time'] ??
                                                              '',
                                                        ) ??
                                                        DateTime.now(),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Location
                                            if (item['location'] != null)
                                              Text(
                                                item['location'],
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      1.5,
                                      12,
                                      1.5,
                                    ),
                                    child: UserPost(
                                      post: item,
                                      currentUserId: _currentUserId ?? 0,
                                      onEdit: handleEdit,
                                      onDelete: handleDelete,
                                      onComment: handleComment,
                                      onLike: handleLike,
                                    ),
                                  );
                            },
                          ),
                        ),
              ),
            ],
          ),
          _buildSearchOverlay(),
        ],
      ),
    );
  }
}
