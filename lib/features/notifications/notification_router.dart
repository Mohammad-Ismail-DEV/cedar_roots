import '../../core/navigation.dart';
import '../shell/app_routes.dart';

/// Opens the screen a notification points at. Used by push taps and by the
/// notifications list, so both always agree.
///
/// [type] is the payload's notificationType; [data] holds string ids
/// (postId, eventId, senderId, ...).
void openNotificationTarget({
  required String type,
  required Map<String, String> data,
}) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  int? id(String key) => int.tryParse(data[key] ?? '');

  final route = switch (type) {
    'chat' => switch (id('senderId')) {
      final senderId? => AppRoutes.chat(
        userId: senderId,
        name: data['senderName'] ?? 'User',
      ),
      _ => null,
    },
    'comment' || 'like' => switch (id('postId')) {
      final postId? => AppRoutes.post(postId),
      _ => null,
    },
    'event_announcement' ||
    'new_event' ||
    'event_invite' ||
    'event_join' ||
    'event_reminder' => switch (id('eventId')) {
      final eventId? => AppRoutes.event(eventId),
      _ => null,
    },
    'connection_request' || 'connection_accept' => switch (id('senderId') ??
        id('receiverId')) {
      final userId? => AppRoutes.profile(userId),
      _ => null,
    },
    'organization_invite' || 'organization_accept' => switch (id(
      'organizationId',
    )) {
      final orgId? => AppRoutes.organization(orgId),
      _ => null,
    },
    _ => null,
  };

  if (route != null) navigator.push(route);
}
