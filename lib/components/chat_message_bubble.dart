import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final VoidCallback? onImageTap;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onImageTap,
  }) : super(key: key);

  String _formatTime(String time) {
    final dateTime = DateTime.parse(time).toLocal();
    return DateFormat.jm().format(dateTime); // 12-hour format
  }

  @override
  Widget build(BuildContext context) {
    final content = message['content'] ?? '';
    final type = message['type'] ?? 'text';
    final sentAt = message['sent_at'] ?? '';
    final readStatus = message['read_status'] ?? false;
    final deliveryStatus = message['status'];

    Widget statusIcon() {
      if (readStatus == true) {
        return Icon(Icons.done_all, size: 14, color: Colors.blue);
      }
      switch (deliveryStatus) {
        case 'sending':
          return Icon(Icons.schedule, size: 14, color: Colors.grey[300]);
        case 'sent':
          return Icon(Icons.check, size: 14, color: Colors.grey[300]);
        case 'delivered':
          return Icon(Icons.done_all, size: 14, color: Colors.grey[300]);
        default:
          return Container();
      }
    }

    Widget bubble;
    if (type == 'image') {
      bubble = GestureDetector(
        onTap: onImageTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(content, width: 200, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 4,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTime(sentAt),
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bubble = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(content, style: TextStyle(color: Colors.white)),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(sentAt),
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              SizedBox(width: 4),
              statusIcon(),
            ],
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: type == 'text' ? EdgeInsets.all(10) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF228B22).withOpacity(0.85) : Colors.grey[600],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: bubble,
      ),
    );
  }
}
