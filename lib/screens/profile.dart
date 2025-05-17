import 'dart:convert';
import 'dart:io';
import 'package:cedar_roots/components/nav_bar.dart';
import 'package:cedar_roots/components/user_post.dart';
import 'package:cedar_roots/screens/organizations.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cedar_roots/screens/login.dart';
import 'package:cedar_roots/screens/connections.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/screens/settings.dart';
import 'package:cedar_roots/components/user_info.dart';
import 'package:cedar_roots/components/comment_section.dart';
import 'package:cedar_roots/screens/create_post.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final bool isCurrentUser;

  const ProfileScreen({Key? key, this.userId, this.isCurrentUser = true})
    : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = "User";
  String _profilePicUrl = "";
  int _connectionsCount = 0;
  String _connectionStatus = "none";
  List<dynamic> _posts = [];
  bool _isPostsLoading = true;
  int? _currentUserId;

  final api = ApiServices(); // Ensure this is initialized somewhere

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } else {
      _currentUserId = prefs.getInt('user_id');
      // Redirect if this is my profile from another screen
      if (!widget.isCurrentUser && widget.userId == _currentUserId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => NavBar(initialIndex: 4)),
          );
        });
      } else {
        _fetchProfileData();
      }
    }
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = widget.userId ?? prefs.getInt('user_id');
    if (userId == null || token == null) return;

    try {
      final userRes = await http.get(
        Uri.parse("http://13.50.2.82:3000/users/$userId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final connCountRes = await http.get(
        Uri.parse("http://13.50.2.82:3000/connections/user/$userId/accepted"),
        headers: {'Authorization': 'Bearer $token'},
      );

      String status = "none";

      if (_currentUserId != null && userId != _currentUserId) {
        final connStatusRes = await http.get(
          Uri.parse(
            "http://13.50.2.82:3000/connections/status/${_currentUserId!}/$userId",
          ),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (connStatusRes.statusCode == 200) {
          final connStatus = jsonDecode(connStatusRes.body);
          status = connStatus['status'] ?? "none";
        }
      }

      if (!mounted) return;

      if (userRes.statusCode == 200 && connCountRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        final connCountData = jsonDecode(connCountRes.body);

        setState(() {
          print("User data: $userData");
          _name = userData['name'] ?? "User";
          _profilePicUrl = userData['profile_pic'] ?? "";
          _connectionsCount = connCountData['count'] ?? 0;
          _connectionStatus = status;
        });
        await _fetchUserPosts(userId, token);
      }
    } catch (e) {
      print("❌ Error fetching profile data: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserPosts(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse("http://13.50.2.82:3000/posts"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final allPosts = jsonDecode(response.body);
        final userPosts =
            allPosts.where((p) => p['user_id'] == userId).toList();

        if (!mounted) return;
        setState(() {
          _posts = userPosts;
          _isPostsLoading = false;
        });
      } else {
        print("⚠️ Failed to load posts");
        if (!mounted) return;
        setState(() => _isPostsLoading = false);
      }
    } catch (e) {
      print("❌ Error fetching posts: $e");
      if (!mounted) return;
      setState(() => _isPostsLoading = false);
    }
  }

  Future<void> _sendConnectionRequest() async {
    final reqRes = await ApiServices().sendConnectionRequest(widget.userId);
    if (reqRes.statusCode == 200) {
      await _fetchProfileData();
    }
  }

  Future<void> _cancelConnectionRequest() async {
    if (_currentUserId == null || widget.userId == null) return;

    try {
      final res = await api.getConnectionBetween(
        _currentUserId!,
        widget.userId!,
      );
      if (res.statusCode == 200) {
        final connData = jsonDecode(res.body);
        final connectionId = connData['id'];

        final response = await api.cancelConnectionRequest(connectionId);
        if (response.statusCode == 200) {
          print('Connection request cancelled.');
          await _fetchProfileData(); // Refresh state
        } else {
          print('Failed to cancel request: ${response.body}');
        }
      } else {
        print('⚠️ Failed to fetch connection ID: ${res.body}');
      }
    } catch (e) {
      print('❌ Error cancelling connection: $e');
    }
  }

  Future<void> _removeConnection() async {
    if (_currentUserId == null || widget.userId == null) return;

    try {
      final res = await api.getConnectionBetween(
        _currentUserId!,
        widget.userId!,
      );
      if (res.statusCode == 200) {
        final connData = jsonDecode(res.body);
        final connectionId = connData['id'];

        final response = await api.removeConnection(connectionId);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Connection removed')));
          await _fetchProfileData(); // Refresh UI
        } else {
          print('Failed to remove connection: ${response.body}');
        }
      } else {
        print('⚠️ Failed to fetch connection ID: ${res.body}');
      }
    } catch (e) {
      print('❌ Error removing connection: $e');
    }
  }

  void handleEdit(int postId) {
    final postToEdit = _posts.firstWhere((p) => p['id'] == postId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreatePostScreen(
              userId: _currentUserId!,
              existingPost: postToEdit,
            ),
      ),
    ).then((_) => _fetchProfileData()); // refresh after editing
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
                child: const Text("Delete"),
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
          _posts.removeWhere((p) => p['id'] == postId);
        });
      }
    }
  }

  Future<void> _respondToConnection(bool accept) async {
    if (_currentUserId == null || widget.userId == null) return;

    try {
      final res = await api.getConnectionBetween(
        _currentUserId!,
        widget.userId!,
      );
      if (res.statusCode == 200) {
        final connData = jsonDecode(res.body);
        final connectionId = connData['id'];

        final response = await api.respondToRequest({
          'connectionId': connectionId,
          'accept': accept,
        });

        if (response.statusCode == 200) {
          print(accept ? '✅ Connection accepted' : '❌ Connection rejected');
          await _fetchProfileData(); // Refresh UI
        } else {
          print('⚠️ Failed to respond to request: ${response.body}');
        }
      } else {
        print('⚠️ Failed to fetch connection: ${res.body}');
      }
    } catch (e) {
      print('❌ Error responding to connection: $e');
    }
  }

  void handleComment(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentSection(postId: postId),
    ).then((_) => _fetchProfileData());
  }

  void toggleLikeForPost(int postId, bool isLiked) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = "http://13.50.2.82:3000/posts/$postId/like";

    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({'like': !isLiked}),
    );

    if (response.statusCode == 200) {
      _fetchProfileData(); // refresh to reflect the updated like count/status
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget connectionButton() {
      Widget buildShadowButton({
        required String label,
        required VoidCallback onTap,
        required Color textColor,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          ),
        );
      }

      switch (_connectionStatus) {
        case "accepted":
          return buildShadowButton(
            label: "Remove Connection",
            onTap: _removeConnection,
            textColor: Colors.red,
          );
        case "pending_sent":
          return buildShadowButton(
            label: "Cancel Request",
            onTap: _cancelConnectionRequest,
            textColor: Colors.red,
          );

        case "pending_received":
          return Row(
            children: [
              Expanded(
                child: buildShadowButton(
                  label: "Accept",
                  onTap: () => _respondToConnection(true),
                  textColor: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: buildShadowButton(
                  label: "Reject",
                  onTap: () => _respondToConnection(false),
                  textColor: Colors.red,
                ),
              ),
            ],
          );

        default:
          return buildShadowButton(
            label: "Connect",
            onTap: _sendConnectionRequest,
            textColor: Colors.green,
          );
      }
    }

    Widget chatButton() {
      return AspectRatio(
        aspectRatio: 1, // makes it square
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChatScreen(receiverId: widget.userId!, name: _name),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
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
            child: const Center(child: Icon(Icons.chat, color: Colors.green)),
          ),
        ),
      );
    }

    Widget manageOrganizationButton(BuildContext context) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizationsScreen(userId: widget.userId ?? 1),
            ), // change id as needed
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.admin_panel_settings, color: Color(0xFF0B1E3A)),
              SizedBox(width: 8),
              Text(
                "Manage Organizations",
                style: TextStyle(color: Color(0xFF0B1E3A), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: widget.isCurrentUser ? null : BackButton(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          UserInfoHeader(
            name: _name,
            profilePicUrl: _profilePicUrl,
            connectionsCount: _connectionsCount,
            isCurrentUser: widget.isCurrentUser,
            onConnectionsTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConnectionsScreen(userId: widget.userId ?? 0),
                ),
              );
            },
            onSettingsTap:
                widget.isCurrentUser
                    ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    )
                    : null,
            onProfileImageTap: _showImagePreview,
            actionButton: null,
          ),
          if (!widget.isCurrentUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_connectionStatus == 'accepted') chatButton(),
                    SizedBox(width: 12),
                    Expanded(child: connectionButton()),
                  ],
                ),
              ),
            ),
          if (widget.isCurrentUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: manageOrganizationButton(context),
            ),
          const Divider(),
          Expanded(
            child:
                _isPostsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _posts.isEmpty
                    ? const Center(child: Text("No posts yet."))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return UserPost(
                          post: post,
                          currentUserId: _currentUserId!,
                          onEdit: handleEdit,
                          onDelete: handleDelete,
                          onComment: handleComment,
                          onLike: toggleLikeForPost,
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          widget.isCurrentUser
              ? SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_currentUserId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CreatePostScreen(userId: _currentUserId!),
                        ),
                      ).then((_) => _fetchProfileData());
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.blue, size: 26),
                  label: const Text(
                    "Create Post",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  void _showImagePreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child:
                        _profilePicUrl.isNotEmpty
                            ? Image.network(_profilePicUrl)
                            : const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (widget.isCurrentUser)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: TextButton(
                        onPressed: _changeProfilePicture,
                        child: const Text(
                          "Change",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final uri = Uri.parse('http://13.50.2.82:3000/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      _updateProfilePicture(data['url']);
    } else {
      print('Upload failed');
    }
  }

  Future<void> _updateProfilePicture(String newImageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('auth_token');
    if (userId == null || token == null) return;

    final response = await http.put(
      Uri.parse('http://13.50.2.82:3000/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'profile_pic': newImageUrl}),
    );

    if (response.statusCode == 200) {
      setState(() => _profilePicUrl = newImageUrl);
    } else {
      print("⚠️ Failed to update profile picture: ${response.body}");
    }
  }
}
