import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatListTile extends StatelessWidget {
  final String name;
  final String content;
  final String? timestamp;
  final int unreadCount;
  final bool isGroup;
  final bool isSentByMe;
  final String status;
  final VoidCallback onTap;

  const ChatListTile({
    Key? key,
    required this.name,
    required this.content,
    required this.timestamp,
    required this.unreadCount,
    required this.isGroup,
    required this.isSentByMe,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        timestamp != null
            ? DateFormat.jm().format(DateTime.parse(timestamp!).toLocal())
            : '';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isGroup ? Colors.green : Colors.blue,
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(content, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (isSentByMe)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Icon(
                status == 'read' || status == 'read_status:true'
                    ? Icons.done_all
                    : status == 'delivered'
                    ? Icons.done_all
                    : status == 'sent'
                    ? Icons.check
                    : Icons.schedule,
                size: 16,
                color:
                    status == 'read'
                        ? Colors.blue
                        : status == 'delivered'
                        ? Colors.grey
                        : status == 'sent'
                        ? Colors.grey
                        : Colors.grey[400],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  '$unreadCount',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
