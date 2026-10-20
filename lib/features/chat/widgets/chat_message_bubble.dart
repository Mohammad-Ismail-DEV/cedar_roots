import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/image_url.dart';
import '../../../core/theme.dart';
import '../../../models/message.dart';
import '../../../shared/widgets/message_status_icon.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onImageTap,
    this.onRetry,
    this.onCancel,
  });

  final Message message;
  final bool isMe;
  final VoidCallback? onImageTap;
  final VoidCallback? onRetry;

  /// Stops an upload in progress, or discards a photo that failed to send.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat.jm().format(message.sentAt);
    // Text on my (accent) bubbles is white; on the other person's it follows the theme.
    final ink = isMe ? Colors.white : scheme.onSurface;
    final softInk = isMe ? Colors.white70 : palette.muted;
    final footer = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            color: message.isImage ? Colors.white70 : softInk,
            fontSize: 10,
          ),
        ),
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
              borderRadius: BorderRadius.circular(16),
              child:
                  message.isLocal
                      ? _localImage()
                      : CachedNetworkImage(
                        httpHeaders: imageHeaders,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (_, __, ___) => const SizedBox(
                              width: 200,
                              height: 120,
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                              ),
                            ),
                      ),
            ),
            if (message.isLocal) Positioned.fill(child: _uploadOverlay()),
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
          Text(
            message.content,
            style: TextStyle(color: ink, fontSize: 15, height: 1.3),
          ),
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
          padding:
              message.isImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color:
                message.isImage
                    ? Colors.transparent
                    : (isMe ? scheme.primary : palette.inputBg),
            borderRadius: BorderRadius.circular(message.isImage ? 16 : 20),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: bubble,
        ),
      ),
    );
  }

  /// The photo straight from this device, shown while it uploads.
  Widget _localImage() {
    final path = message.content;
    return kIsWeb
        ? Image.network(path, width: 200, fit: BoxFit.cover)
        : Image.file(File(path), width: 200, fit: BoxFit.cover);
  }

  /// Dimmed spinner with a cancel button while uploading; retry and discard if it failed.
  Widget _uploadOverlay() {
    final failed = message.status == MessageStatus.failed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child:
              failed
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        tooltip: 'Retry',
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Discard',
                        onPressed: onCancel,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  )
                  : Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel',
                        onPressed: onCancel,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
