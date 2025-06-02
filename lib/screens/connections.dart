import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile.dart';
import 'login.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConnectionsScreen extends StatefulWidget {
  final int userId;
  ConnectionsScreen({required this.userId});

  @override
  _ConnectionsScreenState createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  int currentUserId = 0;
  String token = '';
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> outgoingRequests = [];
  bool loadingConnections = true;
  bool loadingRequests = true;
  bool checkingLogin = true;

  Timer? _debounce;
  Timer? _requestsDebounce;

  final TextEditingController _connectionsSearchController =
      TextEditingController();
  final TextEditingController _requestsSearchController =
      TextEditingController();
  String _connectionsQuery = '';
  String _requestsQuery = '';

  List<Map<String, dynamic>> _searchSuggestions = [];
  List<Map<String, dynamic>> _requestSuggestions = [];
  bool _showSuggestions = false;
  bool _showRequestSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectionsSearchController.addListener(() {
      final query = _connectionsSearchController.text.trim();
      _onSearchChanged(query);
      if (mounted) setState(() => _connectionsQuery = query.toLowerCase());
    });
    _requestsSearchController.addListener(() {
      final query = _requestsSearchController.text.trim();
      _onRequestSearchChanged(query);
      if (mounted) setState(() => _requestsQuery = query.toLowerCase());
    });
    _loadUserAndConnections();
  }

  ModalRoute? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
    _route?.navigator?.widget.observers.whereType<RouteObserver>().forEach(
      (obs) => obs.subscribe(this, _route!),
    );
  }

  @override
  void didPopNext() {
    if (mounted) _fetchConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectionsSearchController.dispose();
    _requestsSearchController.dispose();
    _debounce?.cancel();
    _requestsDebounce?.cancel();

    _route?.navigator?.widget.observers.whereType<RouteObserver>().forEach(
      (obs) => obs.unsubscribe(this),
    );

    super.dispose();
  }

  Future<void> _loadUserAndConnections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        }
      });
      return;
    }

    currentUserId = prefs.getInt('user_id') ?? 0;
    token = prefs.getString('auth_token') ?? '';

    if (currentUserId == 0 || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        }
      });
      return;
    }

    if (mounted) {
      setState(() => checkingLogin = false);
    }

    await _fetchConnections();
  }

  Future<String> _getCacheFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/cached_connections.json';
  }

  Future<void> _saveConnectionsToFile(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    final filePath = await _getCacheFilePath();
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _loadConnectionsFromFile() async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final decoded = jsonDecode(contents);
        return {
          'accepted': List<Map<String, dynamic>>.from(
            decoded['accepted'] ?? [],
          ),
          'requests': List<Map<String, dynamic>>.from(
            decoded['requests'] ?? [],
          ),
          'outgoing': List<Map<String, dynamic>>.from(
            decoded['outgoing'] ?? [],
          ),
        };
      }
    } catch (e) {
      print("❌ Error loading connection cache: $e");
    }
    return {'accepted': [], 'requests': [], 'outgoing': []};
  }

  Future<void> _fetchConnections() async {
    if (!mounted) return;

    // Load from cache first
    final cached = await _loadConnectionsFromFile();
    if (mounted) {
      setState(() {
        connections = cached['accepted'] ?? [];
        requests = cached['requests'] ?? [];
        outgoingRequests = cached['outgoing'] ?? [];
      });
    }

    setState(() {
      loadingConnections = true;
      loadingRequests = true;
    });

    try {
      final res = await ApiServices().fetchUserConnections(widget.userId);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (!mounted) return;
        final accepted = List<Map<String, dynamic>>.from(
          data['accepted'] ?? [],
        );
        final reqs = List<Map<String, dynamic>>.from(data['requests'] ?? []);
        final outgoing = List<Map<String, dynamic>>.from(
          data['outgoing'] ?? [],
        );

        setState(() {
          connections = accepted;
          requests = reqs;
          outgoingRequests = outgoing;
          loadingConnections = false;
          loadingRequests = false;
        });

        // Save to file
        await _saveConnectionsToFile({
          'accepted': accepted,
          'requests': reqs,
          'outgoing': outgoing,
        });
      } else {
        throw Exception('Failed to fetch connections');
      }
    } catch (e) {
      print('❌ Error fetching connections: $e');
      if (!mounted) return;
      setState(() {
        loadingConnections = false;
        loadingRequests = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (query.isNotEmpty) {
        _fetchUserSuggestions(query);
      } else {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
            _searchSuggestions = [];
          });
        }
      }
    });
  }

  Future<void> _fetchUserSuggestions(String query) async {
    try {
      final res = await ApiServices().searchUsersByName(query);
      if (!mounted) return;
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as List<dynamic>;
        final fetched = List<Map<String, dynamic>>.from(data);

        final connectionIds =
            connections.map((c) {
              return c['sender_id'] == widget.userId
                  ? c['Receiver']['id']
                  : c['Sender']['id'];
            }).toSet();

        final filtered =
            fetched.where((u) => !connectionIds.contains(u['id'])).toList();

        if (mounted) {
          setState(() {
            _searchSuggestions = filtered;
            _showSuggestions = true;
          });
        }
      }
    } catch (e) {
      print('❌ Failed to fetch user suggestions: $e');
    }
  }

  void _onRequestSearchChanged(String query) {
    _requestsDebounce?.cancel();
    _requestsDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (query.isNotEmpty) {
        _fetchRequestSuggestions(query);
      } else {
        if (mounted) {
          setState(() {
            _requestSuggestions = [];
            _showRequestSuggestions = false;
          });
        }
      }
    });
  }

  Future<void> _fetchRequestSuggestions(String query) async {
    try {
      final res = await ApiServices().searchUsersByName(query);
      if (!mounted) return;
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as List<dynamic>;
        final fetched = List<Map<String, dynamic>>.from(data);

        final existingIds = {
          ...requests.map(
            (r) =>
                r['sender_id'] == currentUserId
                    ? r['Receiver']['id']
                    : r['Sender']['id'],
          ),
          ...outgoingRequests.map((r) => r['Receiver']['id']),
          ...connections.map(
            (c) =>
                c['sender_id'] == currentUserId
                    ? c['Receiver']['id']
                    : c['Sender']['id'],
          ),
          currentUserId,
        };

        final filtered =
            fetched.where((u) => !existingIds.contains(u['id'])).toList();
        if (mounted) {
          setState(() {
            _requestSuggestions = filtered;
            _showRequestSuggestions = true;
          });
        }
      }
    } catch (e) {
      print('❌ Failed to fetch request suggestions: $e');
    }
  }

  Future<void> _respondToRequest(int connectionId, bool accept) async {
    final res = await ApiServices().respondToRequest({
      'connectionId': connectionId,
      'accept': accept,
    });

    if (!mounted) return;
    if (res.statusCode == 200 && mounted) {
      await _fetchConnections();
    } else {
      print('❌ Failed to respond to request');
    }
  }

  Widget _buildConnectionTile(Map<String, dynamic> connection) {
    Map<String, dynamic> user =
        connection["sender_id"] == widget.userId
            ? connection['Receiver']
            : connection['Sender'];
    return ListTile(
      leading:
          user['profile_pic_blob'] != null &&
                  user['profile_pic_blob'].isNotEmpty
              ? CircleAvatar(
                backgroundImage: NetworkImage(user['profile_pic_blob']),
              )
              : CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
      title: Text(user['name']),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      ProfileScreen(userId: user['id'], isCurrentUser: false),
            ),
          ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> connection) {
    Map<String, dynamic> user =
        connection["sender_id"] == currentUserId
            ? connection['Receiver']
            : connection['Sender'];

    Widget buildIconShadowButton({
      required IconData icon,
      required VoidCallback onTap,
      required Color iconColor,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 20)),
        ),
      );
    }

    return ListTile(
      leading:
          user['profile_pic_blob'] != null &&
                  user['profile_pic_blob'].isNotEmpty
              ? CircleAvatar(
                backgroundImage: MemoryImage(
                  base64Decode(
                    user['profile_pic_blob'].contains(',')
                        ? user['profile_pic_blob'].split(',').last
                        : user['profile_pic_blob'],
                  ),
                ),
              )
              : CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(user['name'], overflow: TextOverflow.ellipsis)),
          Row(
            children: [
              buildIconShadowButton(
                icon: Icons.check,
                onTap: () => _respondToRequest(connection['id'], true),
                iconColor: Colors.green,
              ),
              SizedBox(width: 8),
              buildIconShadowButton(
                icon: Icons.close,
                onTap: () => _respondToRequest(connection['id'], false),
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      ProfileScreen(userId: user['id'], isCurrentUser: false),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return checkingLogin
        ? CircularProgressIndicator()
        : Scaffold(
          appBar: AppBar(
            title: Text('Connections'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [Tab(text: 'Connections'), Tab(text: 'Requests')],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // --- Connections Tab ---
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _connectionsSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search connections...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchConnections,
                      child:
                          loadingConnections
                              ? Center(child: CircularProgressIndicator())
                              : ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                children: [
                                  ...connections
                                      .where((connection) {
                                        final user =
                                            connection["sender_id"] ==
                                                    widget.userId
                                                ? connection['Receiver']
                                                : connection['Sender'];
                                        return user['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(_connectionsQuery);
                                      })
                                      .map(_buildConnectionTile),
                                  if (connections.where((connection) {
                                    final user =
                                        connection["sender_id"] == widget.userId
                                            ? connection['Receiver']
                                            : connection['Sender'];
                                    return user['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_connectionsQuery);
                                  }).isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No matching connections.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  if (_showSuggestions &&
                                      _searchSuggestions.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Suggestions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    ..._searchSuggestions.map(
                                      (user) => ListTile(
                                        leading:
                                            user['profile_pic_blob'] != null &&
                                                    user['profile_pic_blob']
                                                        .isNotEmpty
                                                ? CircleAvatar(
                                                  backgroundImage: MemoryImage(
                                                    base64Decode(
                                                      user['profile_pic_blob']
                                                              .contains(',')
                                                          ? user['profile_pic_blob']
                                                              .split(',')
                                                              .last
                                                          : user['profile_pic_blob'],
                                                    ),
                                                  ),
                                                )
                                                : CircleAvatar(
                                                  backgroundColor: Colors.green,
                                                  child: Text(
                                                    user['name'][0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                        title: Text(user['name']),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => ProfileScreen(
                                                    userId: user['id'],
                                                    isCurrentUser: false,
                                                  ),
                                            ),
                                          );
                                          setState(() {
                                            _showSuggestions = false;
                                            _searchSuggestions = [];
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    ),
                  ),
                ],
              ),

              // --- Requests Tab ---
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _requestsSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search requests...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchConnections,
                      child:
                          loadingRequests
                              ? Center(child: CircularProgressIndicator())
                              : ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                children: [
                                  ...requests
                                      .where((connection) {
                                        final user =
                                            connection["sender_id"] ==
                                                    currentUserId
                                                ? connection['Receiver']
                                                : connection['Sender'];
                                        return user['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(_requestsQuery);
                                      })
                                      .map(_buildRequestTile),
                                  if (requests.where((connection) {
                                    final user =
                                        connection["sender_id"] == currentUserId
                                            ? connection['Receiver']
                                            : connection['Sender'];
                                    return user['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_requestsQuery);
                                  }).isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No incoming requests found.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  if (outgoingRequests.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Outgoing Requests',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    ...outgoingRequests
                                        .where(
                                          (req) => req['Receiver']['name']
                                              .toString()
                                              .toLowerCase()
                                              .contains(_requestsQuery),
                                        )
                                        .map(
                                          (req) => ListTile(
                                            leading:
                                                req['Receiver']['profile_pic'] !=
                                                            null &&
                                                        req['Receiver']['profile_pic']
                                                            .isNotEmpty
                                                    ? CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                        req['Receiver']['profile_pic'],
                                                      ),
                                                    )
                                                    : CircleAvatar(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      child: Text(
                                                        req['Receiver']['name'][0]
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                            title: Text(
                                              req['Receiver']['name'],
                                            ),
                                            subtitle: Text('Pending approval'),
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => ProfileScreen(
                                                          userId:
                                                              req['Receiver']['id'],
                                                          isCurrentUser: false,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                  ],
                                  if (_showRequestSuggestions &&
                                      _requestSuggestions.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Suggestions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    ..._requestSuggestions.map(
                                      (user) => ListTile(
                                        leading:
                                            user['profile_pic_blob'] != null &&
                                                    user['profile_pic_blob']
                                                        .isNotEmpty
                                                ? CircleAvatar(
                                                  backgroundImage: MemoryImage(
                                                    base64Decode(
                                                      user['profile_pic_blob']
                                                              .contains(',')
                                                          ? user['profile_pic_blob']
                                                              .split(',')
                                                              .last
                                                          : user['profile_pic_blob'],
                                                    ),
                                                  ),
                                                )
                                                : CircleAvatar(
                                                  backgroundColor: Colors.green,
                                                  child: Text(
                                                    user['name'][0]
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                        title: Text(user['name']),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => ProfileScreen(
                                                    userId: user['id'],
                                                    isCurrentUser: false,
                                                  ),
                                            ),
                                          );
                                          setState(() {
                                            _showRequestSuggestions = false;
                                            _requestSuggestions = [];
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
