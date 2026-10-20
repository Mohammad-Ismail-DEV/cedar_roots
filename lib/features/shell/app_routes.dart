import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../chat/chat_screen.dart';
import '../chat/chats_screen.dart';
import '../notifications/notifications_screen.dart';
import '../connections/connections_screen.dart';
import '../events/create_event_screen.dart';
import '../events/event_details_screen.dart';
import '../organizations/manage_organization_screen.dart';
import '../organizations/organization_form_screen.dart';
import '../organizations/organization_members_screen.dart';
import '../organizations/organization_screen.dart';
import '../organizations/organizations_screen.dart';
import '../posts/create_post_screen.dart';
import '../posts/post_details_screen.dart';
import '../profile/profile_screen.dart';

/// Every screen-to-screen jump goes through here, so a screen's constructor can
/// change without touching its callers.
class AppRoutes {
  AppRoutes._();

  static Route<T> _page<T>(Widget screen) =>
      MaterialPageRoute<T>(builder: (_) => screen);

  static Route<void> notifications() => _page(const NotificationsScreen());

  static Route<void> chats() => _page(const ChatsScreen());

  static Route<void> profile(int userId) =>
      _page(ProfileScreen(userId: userId));

  static Route<void> connections(int userId) =>
      _page(ConnectionsScreen(userId: userId));

  static Route<void> chat({required int userId, required String name}) =>
      _page(ChatScreen(receiverId: userId, name: name));

  static Route<void> post(int postId) =>
      _page(PostDetailsScreen(postId: postId));

  static Route<bool> createPost({Post? editing}) =>
      _page(CreatePostScreen(existingPost: editing));

  static Route<void> event(int eventId) =>
      _page(EventDetailsScreen(eventId: eventId));

  static Route<bool> createEvent(int organizationId) =>
      _page(CreateEventScreen(organizationId: organizationId));

  static Route<void> organizations(int userId) =>
      _page(OrganizationsScreen(userId: userId));

  static Route<bool> organization(int organizationId) =>
      _page(OrganizationScreen(organizationId: organizationId));

  /// Creates an organization, or edits [organizationId].
  static Route<bool> organizationForm({int? organizationId}) =>
      _page(OrganizationFormScreen(organizationId: organizationId));

  static Route<bool> manageOrganization(int organizationId) =>
      _page(ManageOrganizationScreen(organizationId: organizationId));

  static Route<void> organizationMembers(int organizationId) =>
      _page(OrganizationMembersScreen(organizationId: organizationId));
}
