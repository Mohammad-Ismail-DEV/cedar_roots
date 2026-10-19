import 'package:flutter/material.dart';

import '../../core/navigation.dart';
import '../chat/chat_screen.dart';
import '../../screens/event_details.dart';
import '../../screens/organization.dart';
import '../../screens/post_details.dart';
import '../../screens/profile.dart';

/// Opens the screen a notification points at. Used by push taps and by the
/// notifications list, so both always agree.
///
/// [type] is the payload's notificationType; [data] holds string ids
/// (postId, eventId, senderId, ...).
void openNotificationTarget({
  required String type,
  required Map<String, String> data,
  required int myUserId,
}) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  int? id(String key) => int.tryParse(data[key] ?? '');

  final Widget? target = switch (type) {
    'chat' => switch (id('senderId')) {
      final senderId? => ChatScreen(
        receiverId: senderId,
        name: data['senderName'] ?? 'User',
      ),
      _ => null,
    },
    'comment' || 'like' => switch (id('postId')) {
      final postId? => PostDetailsScreen(postId: postId, userId: myUserId),
      _ => null,
    },
    'event_announcement' ||
    'new_event' ||
    'event_invite' ||
    'event_join' => switch (id('eventId')) {
      final eventId? => EventDetailsScreen(eventId: eventId, userId: myUserId),
      _ => null,
    },
    'connection_request' || 'connection_accept' => switch (id('senderId') ??
        id('receiverId')) {
      final userId? => ProfileScreen(userId: userId, isCurrentUser: false),
      _ => null,
    },
    'organization_invite' || 'organization_accept' => switch (id(
      'organizationId',
    )) {
      final orgId? => OrganizationScreen(organizationId: orgId),
      _ => null,
    },
    _ => null,
  };

  if (target != null) {
    navigator.push(MaterialPageRoute(builder: (_) => target));
  }
}
