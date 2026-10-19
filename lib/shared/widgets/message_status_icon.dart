import 'package:flutter/material.dart';

import '../../models/message.dart';

/// Tick icon for a message I sent: clock, one tick, two ticks, blue two ticks.
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 14,
    this.idleColor,
  });

  final MessageStatus status;
  final double size;

  /// Colour for every state except "seen" and "failed".
  final Color? idleColor;

  @override
  Widget build(BuildContext context) {
    final idle = idleColor ?? Colors.grey[300]!;
    return switch (status) {
      MessageStatus.sending => Icon(Icons.schedule, size: size, color: idle),
      MessageStatus.sent => Icon(Icons.check, size: size, color: idle),
      MessageStatus.delivered => Icon(Icons.done_all, size: size, color: idle),
      MessageStatus.seen => Icon(
        Icons.done_all,
        size: size,
        color: Colors.blue,
      ),
      MessageStatus.failed => Icon(
        Icons.error_outline,
        size: size,
        color: Colors.redAccent,
      ),
    };
  }
}
