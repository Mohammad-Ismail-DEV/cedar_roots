import 'json_helpers.dart';
import 'user.dart';

class EventOrganization {
  const EventOrganization({
    required this.id,
    required this.name,
    this.logo,
    this.logoBlob,
  });

  final int id;
  final String name;
  final String? logo;
  final String? logoBlob;

  factory EventOrganization.fromJson(Map<String, dynamic> json) =>
      EventOrganization(
        id: asInt(json['id']),
        name: (json['name'] ?? '').toString(),
        logo: asStringOrNull(json['logo']),
        logoBlob: asStringOrNull(json['logo_blob']),
      );
}

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.organizationId,
    this.description,
    this.location,
    this.dateTime,
    this.createdAt,
    this.organization,
    this.participantCount = 0,
    this.isParticipant = false,
  });

  final int id;
  final String title;
  final int organizationId;
  final String? description;
  final String? location;
  final DateTime? dateTime;
  final DateTime? createdAt;
  final EventOrganization? organization;

  /// How many people joined, and whether the signed-in user is one of them (events list only).
  final int participantCount;
  final bool isParticipant;

  Event copyWith({int? participantCount, bool? isParticipant}) => Event(
    id: id,
    title: title,
    organizationId: organizationId,
    description: description,
    location: location,
    dateTime: dateTime,
    createdAt: createdAt,
    organization: organization,
    participantCount: participantCount ?? this.participantCount,
    isParticipant: isParticipant ?? this.isParticipant,
  );

  factory Event.fromJson(Map<String, dynamic> json) {
    final org = asMap(json['Organization']);
    return Event(
      id: asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      organizationId: asInt(json['organization_id']),
      description: asStringOrNull(json['description']),
      location: asStringOrNull(json['location']),
      dateTime: asDate(json['date_time']),
      createdAt: asDate(json['created_at']),
      organization: org == null ? null : EventOrganization.fromJson(org),
      participantCount: asInt(json['participant_count']),
      isParticipant: json['is_participant'] == true,
    );
  }
}

class EventParticipant {
  const EventParticipant({required this.userId, required this.role, this.user});

  final int userId;
  final String role;
  final User? user;

  bool get isCollaborator => role == 'collaborator';

  factory EventParticipant.fromJson(Map<String, dynamic> json) =>
      EventParticipant(
        userId: asInt(json['user_id']),
        role: (json['role'] ?? 'attendee').toString(),
        user: User.maybe(json['User']),
      );
}

class Announcement {
  const Announcement({required this.id, required this.message, this.createdAt});

  final int id;
  final String message;
  final DateTime? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: asInt(json['id']),
    message: (json['message'] ?? '').toString(),
    createdAt: asDate(json['created_at']),
  );
}
