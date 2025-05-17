import 'package:cedar_roots/screens/connections.dart';
import 'package:cedar_roots/screens/home.dart';
import 'package:cedar_roots/screens/notifications.dart';
import 'package:cedar_roots/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavBar extends StatefulWidget {
  final int? initialIndex;

  NavBar({this.initialIndex});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;
  int? userId;
  bool _isLoading = true;

  @override
  void initState() {
    _selectedIndex = widget.initialIndex ?? 0;
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getInt('user_id') != null) {
        userId = prefs.getInt('user_id');
      } else {
        userId = 0;
      }
      _isLoading = false;
    });
  }

  List<Widget> get _screens => [
    HomeScreen(),
    ConnectionsScreen(userId: userId!),
    NotificationsScreen(),
    ProfileScreen(userId: userId),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Home icon
            label: 'Home',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group), // Connections icon
            label: 'Connections',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), // Notifications icon
            label: 'Notifications',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // Profile icon
            label: 'Profile',
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
