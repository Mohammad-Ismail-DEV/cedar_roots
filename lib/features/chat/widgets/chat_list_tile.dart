import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
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
    final palette = context.palette;
    final last = conversation.lastMessage;
    final sentByMe = last != null && last.senderId == myUserId;
    final unread = conversation.unreadCount > 0;
    final preview =
        last == null
            ? ''
            : '${sentByMe ? 'You: ' : ''}${last.isImage ? 'Photo' : last.content}';
    final time = last == null ? '' : DateFormat.jm().format(last.sentAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            UserAvatar(
              name: conversation.name,
              imageUrl: conversation.profilePic,
              radius: 28,
              backgroundColor: palette.avatarBg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$preview${time.isEmpty ? '' : ' · $time'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: unread ? null : palette.muted,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (sentByMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: MessageStatusIcon(
                            status: last.status,
                            size: 14,
                            idleColor: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
