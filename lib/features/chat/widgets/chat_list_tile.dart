import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/message.dart';
import '../../../shared/widgets/message_status_icon.dart';
import '../../../shared/widgets/user_avatar.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.conversation,
    required this.myUserId,
    required this.onTap,
  });

  final Conversation conversation;
  final int myUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    final sentByMe = last != null && last.senderId == myUserId;
    final preview =
        last == null ? '' : (last.isImage ? '📷 image' : last.content);
    final time = last == null ? '' : DateFormat.jm().format(last.sentAt);

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(
        name: conversation.name,
        imageUrl: conversation.profilePic,
      ),
      title: Text(conversation.name),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (sentByMe)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: MessageStatusIcon(
                status: last.status,
                size: 16,
                idleColor: Colors.grey,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          if (conversation.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
