import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../shared/widgets/user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.connectionsCount,
    required this.onConnectionsTap,
    this.onSettingsTap,
    this.onAvatarTap,
  });

  final User user;
  final int connectionsCount;
  final VoidCallback onConnectionsTap;

  /// Only passed for the signed-in user's own profile.
  final VoidCallback? onSettingsTap;
  final VoidCallback? onAvatarTap;

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    const shadow = [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: UserAvatar(
              name: user.name,
              blob: user.profilePicBlob,
              imageUrl: user.profilePic,
              radius: 36,
              backgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: onConnectionsTap,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: shadow,
                    ),
                    child: Text(
                      '${_formatCount(connectionsCount)} connections',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsTap != null)
            GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: shadow,
                ),
                child: const Icon(Icons.settings, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}
