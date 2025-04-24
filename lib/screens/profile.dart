import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cedar_roots/screens/login.dart';
import 'package:cedar_roots/screens/connections.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/screens/settings.dart';
import 'package:cedar_roots/components/user_info.dart';

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
  bool _isConnected = false;

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
      _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = widget.userId ?? prefs.getInt('user_id');
    if (userId == null || token == null) return;

    try {
      final userRes = await http.get(
        Uri.parse("http://13.48.155.59:3000/users/$userId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final connRes = await http.get(
        Uri.parse("http://13.48.155.59:3000/connections/user/$userId/accepted"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return; // 🚨 ADD THIS BEFORE setState
      if (userRes.statusCode == 200 && connRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        final connData = jsonDecode(connRes.body);

        if (!mounted) return; // 🚨 AGAIN before setState
        setState(() {
          _name = userData['name'] ?? "User";
          _profilePicUrl = userData['profile_pic'] ?? "";
          _connectionsCount = connData['count'] ?? 0;
          _isConnected = userData['is_connected'] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching profile data: $e");
    } finally {
      if (!mounted) return; // 🚨 And here too
      setState(() => _isLoading = false);
    }
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
    final uri = Uri.parse('http://13.48.155.59:3000/upload');

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
      Uri.parse('http://13.48.155.59:3000/users/$userId'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: widget.isCurrentUser ? null : BackButton(),
        title: null,
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
            onConnectionsTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConnectionsScreen()),
                ),
            onSettingsTap:
                widget.isCurrentUser
                    ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    )
                    : null,
            onProfileImageTap: _showImagePreview,
            actionButton:
                !widget.isCurrentUser
                    ? ElevatedButton(
                      onPressed: () {
                        if (_isConnected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatScreen(
                                    receiverId: widget.userId!,
                                    name: _name,
                                  ),
                            ),
                          );
                        } else {
                          // Send connection request logic
                        }
                      },
                      child: Text(_isConnected ? 'Chat' : 'Connect'),
                    )
                    : null,
          ),
          const Divider(),
          Expanded(child: Center(child: Text('User posts go here'))),
        ],
      ),
    );
  }
}
