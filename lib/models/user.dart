import 'json_helpers.dart';

class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.profilePic,
    this.profilePicBlob,
    this.bio,
    this.location,
  });

  final int id;
  final String name;
  final String? email;
  final String? profilePic;

  /// Small base64 data URI the server pre-renders for list views.
  final String? profilePicBlob;
  final String? bio;
  final String? location;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: asInt(json['id']),
    name: (json['name'] ?? '').toString(),
    email: asStringOrNull(json['email']),
    profilePic: asStringOrNull(json['profile_pic']),
    profilePicBlob: asStringOrNull(json['profile_pic_blob']),
    bio: asStringOrNull(json['bio']),
    location: asStringOrNull(json['location']),
  );

  static User? maybe(Object? json) {
    final map = asMap(json);
    return map == null ? null : User.fromJson(map);
  }
}
