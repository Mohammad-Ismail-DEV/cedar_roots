/// Notification settings kept on the server (so they follow you to a new phone).
class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.eventReminders = true,
  });

  final bool pushEnabled;
  final bool eventReminders;

  NotificationPreferences copyWith({bool? pushEnabled, bool? eventReminders}) =>
      NotificationPreferences(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        eventReminders: eventReminders ?? this.eventReminders,
      );

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        pushEnabled: json['push_enabled'] != false,
        eventReminders: json['event_reminders'] != false,
      );
}
