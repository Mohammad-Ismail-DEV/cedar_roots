import 'event.dart';
import 'json_helpers.dart';
import 'organization.dart';
import 'post.dart';
import 'user.dart';

class SearchResults {
  const SearchResults({
    this.users = const [],
    this.organizations = const [],
    this.events = const [],
    this.posts = const [],
  });

  final List<User> users;
  final List<Organization> organizations;
  final List<Event> events;
  final List<Post> posts;

  bool get isEmpty =>
      users.isEmpty && organizations.isEmpty && events.isEmpty && posts.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
    users: asMapList(json['users']).map(User.fromJson).toList(),
    organizations:
        asMapList(json['organizations']).map(Organization.fromJson).toList(),
    events: asMapList(json['events']).map(Event.fromJson).toList(),
    posts: asMapList(json['posts']).map(Post.fromJson).toList(),
  );
}
