import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../screens/connections.dart';
import '../../screens/home.dart';
import '../../screens/notifications.dart';
import '../../screens/profile.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    // Guests (not signed in) can still browse; screens treat userId 0 as "nobody".
    final userId = ref.watch(currentUserIdProvider) ?? 0;

    final screens = <Widget>[
      HomeScreen(),
      ConnectionsScreen(userId: userId),
      NotificationsScreen(),
      ProfileScreen(userId: userId),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Connections',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
