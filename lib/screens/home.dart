import 'package:cedar_roots/screens/chats.dart';
import 'package:cedar_roots/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initFirebase();
  }

  // Method to check login status from SharedPreferences
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      FirebaseNotificationService().initialize();
    });
  }

  Future<void> _initFirebase() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool("isLoggedIn") == true) {
      setState(() {
        FirebaseNotificationService().initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cedar Roots'),
        actions: [
          // Only show the chat button if the user is logged in
          if (_isLoggedIn)
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatsScreen()),
                );
              },
            ),
        ],
      ),
      body: Center(child: Text('Home Screen')),
    );
  }
}
