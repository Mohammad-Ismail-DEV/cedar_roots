import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/image_url.dart';
import '../../../models/message.dart';
import '../../../shared/widgets/message_status_icon.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onImageTap,
    this.onRetry,
  });

  final Message message;
  final bool isMe;
  final VoidCallback? onImageTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(message.sentAt);
    final footer = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        if (isMe) ...[
          const SizedBox(width: 4),
          MessageStatusIcon(status: message.status),
        ],
      ],
    );

    final Widget bubble;
    if (message.isImage) {
      bubble = GestureDetector(
        onTap: onImageTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: sizedImageUrl(
                  message.content,
                  logicalWidth: 200,
                  pixelRatio: MediaQuery.devicePixelRatioOf(context),
                ),
                width: 200,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => const SizedBox(
                      width: 200,
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                errorWidget:
                    (_, __, ___) => const SizedBox(
                      width: 200,
                      height: 120,
                      child: Icon(Icons.broken_image, color: Colors.white70),
                    ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: footer,
              ),
            ),
          ],
        ),
      );
    } else {
      bubble = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(message.content, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          footer,
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: message.status == MessageStatus.failed ? onRetry : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          padding: message.isImage ? EdgeInsets.zero : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isMe
                    ? const Color(0xFF228B22).withValues(alpha: 0.85)
                    : Colors.grey[600],
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: bubble,
        ),
      ),
    );
  }
}
