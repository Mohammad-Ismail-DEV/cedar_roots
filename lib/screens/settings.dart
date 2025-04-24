
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cedar_roots/screens/login.dart';
import 'package:cedar_roots/services/socket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Arabic', 'French'];

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await SocketService().removeFCMToken();
    SocketService().disconnect();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _deleteAccount() async {
    // TODO: Implement actual delete logic with confirmation and API call
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // API call and clearing preferences
              Navigator.pop(context);
              logout();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.green)),
        iconTheme: const IconThemeData(color: Colors.green),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("General", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Notifications"),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Languages"),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: Container(),
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text("Change Email"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to change email screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text("Change/Add Number"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to change number screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to change password screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Sign Out"),
                  onTap: logout,
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                  onTap: _deleteAccount,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
