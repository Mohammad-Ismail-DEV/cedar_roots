import 'dart:convert';

import 'json_helpers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.data,
    this.createdAt,
  });

  final int id;
  final String type;
  final String message;
  final bool isRead;

  /// Payload keys (all string values), e.g. postId, senderId, eventId.
  final Map<String, String> data;
  final DateTime? createdAt;

  /// The server stores the payload as JSON; older rows may hold a JSON string.
  static Map<String, String> _parseData(Object? raw) {
    Object? value = raw;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        value = null;
      }
    }
    final map = asMap(value);
    return map == null ? {} : map.map((k, v) => MapEntry(k, '$v'));
  }

  /// The routing type: the payload's notificationType wins over the row type.
  String get routeType => data['notificationType'] ?? type;

  int? get senderId =>
      int.tryParse(data['senderId'] ?? data['receiverId'] ?? '');

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    message: message,
    isRead: isRead ?? this.isRead,
    data: data,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: asInt(json['id']),
        type: (json['type'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        isRead: json['is_read'] == true || json['is_read'] == 1,
        data: _parseData(json['data']),
        createdAt: asDate(json['created_at']),
      );
}
