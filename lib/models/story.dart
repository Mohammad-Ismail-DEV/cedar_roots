import 'json_helpers.dart';
import 'user.dart';

/// One photo or text card inside someone's story.
class Story {
  const Story({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    required this.viewed,
    this.imageUrl,
    this.text,
    this.bg = 0,
    this.viewCount,
  });

  final int id;

  /// `image` or `text`.
  final String type;
  final String? imageUrl;
  final String? text;

  /// Which gradient a text story uses.
  final int bg;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Whether I have watched it (always true for my own).
  final bool viewed;

  /// How many people watched it. Only present on my own stories.
  final int? viewCount;

  bool get isImage => type == 'image';

  Story copyWith({bool? viewed}) => Story(
    id: id,
    type: type,
    imageUrl: imageUrl,
    text: text,
    bg: bg,
    createdAt: createdAt,
    expiresAt: expiresAt,
    viewed: viewed ?? this.viewed,
    viewCount: viewCount,
  );

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: asInt(json['id']),
    type: (json['type'] ?? 'text').toString(),
    imageUrl: asStringOrNull(json['image_url']),
    text: asStringOrNull(json['text']),
    bg: asInt(json['bg']),
    createdAt: asDate(json['created_at']) ?? DateTime.now(),
    expiresAt: asDate(json['expires_at']) ?? DateTime.now(),
    viewed: json['viewed'] == true,
    viewCount: asIntOrNull(json['view_count']),
  );
}

/// Everything one person has posted to their story in the last 24 hours, oldest first.
class StoryGroup {
  const StoryGroup({required this.user, required this.stories});

  final User user;
  final List<Story> stories;

  bool get allSeen => stories.every((s) => s.viewed);

  /// The first story I have not watched, so playback resumes where I left off.
  int get firstUnseenIndex {
    final i = stories.indexWhere((s) => !s.viewed);
    return i < 0 ? 0 : i;
  }

  StoryGroup markViewed(int storyId) => StoryGroup(
    user: user,
    stories: [
      for (final s in stories) s.id == storyId ? s.copyWith(viewed: true) : s,
    ],
  );

  factory StoryGroup.fromJson(Map<String, dynamic> json) => StoryGroup(
    user: User.fromJson(asMap(json['user'])!),
    stories: asMapList(json['stories']).map(Story.fromJson).toList(),
  );
}

/// Someone who watched my story.
class StoryViewer {
  const StoryViewer({required this.user, required this.viewedAt});

  final User user;
  final DateTime? viewedAt;

  factory StoryViewer.fromJson(Map<String, dynamic> json) => StoryViewer(
    user: User.fromJson(asMap(json['user'])!),
    viewedAt: asDate(json['viewed_at']),
  );
}
