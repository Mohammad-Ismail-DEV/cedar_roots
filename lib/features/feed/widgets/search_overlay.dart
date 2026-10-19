import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui.dart';
import '../../../data/search_repository.dart';
import '../../../models/search_results.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../shell/app_routes.dart';

/// Floating card of search results grouped by type.
class SearchOverlay extends ConsumerWidget {
  const SearchOverlay({super.key, required this.query});

  final String query;

  void _open(BuildContext context, Route<void> route) {
    FocusScope.of(context).unfocus();
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));

    return Positioned(
      left: 12,
      right: 12,
      top: 72,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Card(
          elevation: 6,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(errorMessage(e))),
              data: (data) => _results(context, data),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context, SearchResults data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No results found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      children: [
        if (data.users.isNotEmpty) ...[
          const _SectionTitle('Users'),
          for (final user in data.users)
            ListTile(
              leading: UserAvatar(name: user.name, imageUrl: user.profilePic),
              title: Text(user.name),
              onTap: () => _open(context, AppRoutes.profile(user.id)),
            ),
        ],
        if (data.organizations.isNotEmpty) ...[
          const _SectionTitle('Organizations'),
          for (final org in data.organizations)
            ListTile(
              leading: UserAvatar(name: org.name, imageUrl: org.logo),
              title: Text(org.name),
              onTap: () => _open(context, AppRoutes.organization(org.id)),
            ),
        ],
        if (data.events.isNotEmpty) ...[
          const _SectionTitle('Events'),
          for (final event in data.events)
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(event.title),
              onTap: () => _open(context, AppRoutes.event(event.id)),
            ),
        ],
        if (data.posts.isNotEmpty) ...[
          const _SectionTitle('Posts'),
          for (final post in data.posts)
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    post.imageUrl != null ? NetworkImage(post.imageUrl!) : null,
                child:
                    post.imageUrl == null ? const Icon(Icons.post_add) : null,
              ),
              title: Text(
                post.content.split('\n').first,
                overflow: TextOverflow.ellipsis,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
