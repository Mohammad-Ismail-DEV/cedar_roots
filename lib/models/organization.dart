import 'event.dart';
import 'json_helpers.dart';
import 'user.dart';

enum OrgRole {
  owner,
  admin,
  member;

  static OrgRole? parse(Object? value) {
    for (final r in OrgRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }

  bool get canManage => this == owner || this == admin;
}

class OrgMember {
  const OrgMember({
    required this.userId,
    required this.organizationId,
    required this.role,
    this.user,
  });

  final int userId;
  final int organizationId;
  final OrgRole role;
  final User? user;

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
    userId: asInt(json['user_id']),
    organizationId: asInt(json['organization_id']),
    role: OrgRole.parse(json['role']) ?? OrgRole.member,
    user: User.maybe(json['User']),
  );
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.website,
    this.logo,
    this.logoBlob,
    this.members = const [],
    this.followers = const [],
    this.events = const [],
  });

  final int id;
  final String name;
  final String? description;
  final String? location;
  final String? website;
  final String? logo;
  final String? logoBlob;
  final List<OrgMember> members;
  final List<User> followers;
  final List<Event> events;

  bool isFollowedBy(int userId) => followers.any((u) => u.id == userId);

  OrgRole? roleOf(int userId) {
    for (final m in members) {
      if (m.userId == userId) return m.role;
    }
    return null;
  }

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    id: asInt(json['id']),
    name: (json['name'] ?? '').toString(),
    description: asStringOrNull(json['description']),
    location: asStringOrNull(json['location']),
    website: asStringOrNull(json['website']),
    logo: asStringOrNull(json['logo']),
    logoBlob: asStringOrNull(json['logo_blob']),
    members:
        asMapList(json['OrganizationMembers']).map(OrgMember.fromJson).toList(),
    followers:
        asMapList(
          json['OrganizationFollowers'],
        ).map((f) => User.maybe(f['User'])).whereType<User>().toList(),
    events: asMapList(json['Events']).map(Event.fromJson).toList(),
  );
}
