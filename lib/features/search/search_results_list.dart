import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../data/search_repository.dart';
import '../../models/search_results.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';

/// Search results grouped by Users, Organizations, Events and Posts.
class SearchResultsList extends ConsumerWidget {
  const SearchResultsList({super.key, required this.query});

  final String query;

  void _open(BuildContext context, Route<void> route) {
    FocusScope.of(context).unfocus();
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(errorMessage(e))),
      data: (data) => _results(context, data),
    );
  }

  Widget _results(BuildContext context, SearchResults data) {
    final palette = context.palette;

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No results found.',
          style: TextStyle(color: palette.muted),
        ),
      );
    }

    Widget row({
      required Widget leading,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
    }) => ListTile(
      leading: leading,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle:
          subtitle == null || subtitle.isEmpty
              ? null
              : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.muted),
              ),
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (data.users.isNotEmpty) ...[
          const _SectionTitle('Users'),
          for (final user in data.users)
            row(
              leading: UserAvatar(
                name: user.name,
                imageUrl: user.profilePic,
                blob: user.profilePicBlob,
                radius: 22,
                backgroundColor: palette.avatarBg,
              ),
              title: user.name,
              subtitle: user.bio,
              onTap: () => _open(context, AppRoutes.profile(user.id)),
            ),
        ],
        if (data.organizations.isNotEmpty) ...[
          const _SectionTitle('Organizations'),
          for (final org in data.organizations)
            row(
              leading: UserAvatar(
                name: org.name,
                imageUrl: org.logo,
                blob: org.logoBlob,
                radius: 22,
                backgroundColor: palette.avatarBg,
              ),
              title: org.name,
              subtitle: org.location,
              onTap: () => _open(context, AppRoutes.organization(org.id)),
            ),
        ],
        if (data.events.isNotEmpty) ...[
          const _SectionTitle('Events'),
          for (final event in data.events)
            row(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: palette.avatarBg,
                child: Icon(Icons.event, color: palette.avatarInk),
              ),
              title: event.title,
              subtitle: event.location,
              onTap: () => _open(context, AppRoutes.event(event.id)),
            ),
        ],
        if (data.posts.isNotEmpty) ...[
          const _SectionTitle('Posts'),
          for (final post in data.posts)
            row(
              leading: UserAvatar(
                name: post.author?.name ?? '?',
                imageUrl: post.author?.profilePic,
                blob: post.author?.profilePicBlob,
                radius: 22,
                backgroundColor: palette.avatarBg,
              ),
              title: post.content.split('\n').first,
              subtitle: post.author?.name,
              onTap: () => _open(context, AppRoutes.post(post.id)),
            ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
