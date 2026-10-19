import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../screens/event_details.dart';
import '../../screens/organization.dart';
import '../connections/connections_screen.dart';
import '../../screens/organizations.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import '../posts/create_post_screen.dart';
import '../posts/post_details_screen.dart';

/// Every screen-to-screen jump goes through here, so a screen's constructor can
/// change without touching its callers.
class AppRoutes {
  AppRoutes._();

  static Route<T> _page<T>(Widget screen) =>
      MaterialPageRoute<T>(builder: (_) => screen);

  static Route<void> profile(int userId) =>
      _page(ProfileScreen(userId: userId));

  static Route<void> connections(int userId) =>
      _page(ConnectionsScreen(userId: userId));

  static Route<void> organizations(int userId) =>
      _page(OrganizationsScreen(userId: userId));

  static Route<void> organization(int organizationId) =>
      _page(OrganizationScreen(organizationId: organizationId));

  static Route<void> event(int eventId) =>
      _page(EventDetailsScreen(eventId: eventId, userId: 0));

  static Route<void> post(int postId) =>
      _page(PostDetailsScreen(postId: postId));

  static Route<bool> createPost({Post? editing}) =>
      _page(CreatePostScreen(existingPost: editing));

  static Route<void> chat({required int userId, required String name}) =>
      _page(ChatScreen(receiverId: userId, name: name));
}
