import 'json_helpers.dart';

/// Whether a connection is online right now, and when they were last seen.
class Presence {
  const Presence({required this.online, this.lastSeenAt});

  final bool online;
  final DateTime? lastSeenAt;

  static const unknown = Presence(online: false);

  factory Presence.fromJson(Map<String, dynamic> json) => Presence(
    online: json['online'] == true,
    lastSeenAt: asDate(json['last_seen_at']),
  );

  /// "Active now", "Active 5m ago", "Active 3h ago" or '' when never seen.
  String label({DateTime? now}) {
    if (online) return 'Active now';
    final seen = lastSeenAt;
    if (seen == null) return '';
    final diff = (now ?? DateTime.now()).difference(seen);
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }
}
