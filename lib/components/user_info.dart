
import 'package:flutter/material.dart';

class UserInfoHeader extends StatelessWidget {
  final String name;
  final String profilePicUrl;
  final int connectionsCount;
  final bool isCurrentUser;
  final VoidCallback onConnectionsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileImageTap;
  final Widget? actionButton;

  const UserInfoHeader({
    super.key,
    required this.name,
    required this.profilePicUrl,
    required this.connectionsCount,
    required this.isCurrentUser,
    required this.onConnectionsTap,
    this.onSettingsTap,
    this.onProfileImageTap,
    this.actionButton,
  });

  String _formatCount(int count) {
    if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}K";
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onProfileImageTap,
            child: CircleAvatar(
              radius: 36,
              backgroundImage: profilePicUrl.isNotEmpty
                  ? NetworkImage(profilePicUrl)
                  : null,
              child: profilePicUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: onConnectionsTap,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Text(
                      "${_formatCount(connectionsCount)} connections",
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser && onSettingsTap != null)
            GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: const Icon(Icons.settings, color: Colors.black87),
              ),
            )
          else
            if (actionButton != null) actionButton!,
        ],
      ),
    );
  }
}
