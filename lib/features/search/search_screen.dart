import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../models/event.dart';
import '../../shared/widgets/post_tile.dart';
import '../events/event_style.dart';
import '../feed/feed_provider.dart';
import '../shell/app_routes.dart';
import 'search_results_list.dart';

/// The Search tab: a grid of things to explore until you type, then grouped results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(currentUserIdProvider) != null;
    final items = ref.watch(feedProvider).valueOrNull ?? const <FeedItem>[];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        toolbarHeight: 60,
        title: TextField(
          controller: _controller,
          enabled: loggedIn,
          onChanged: loggedIn ? _onChanged : null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: loggedIn ? 'Search' : 'Login to search',
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      body:
          _query.isEmpty
              ? _ExploreGrid(items: items)
              : SearchResultsList(query: _query),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.items});

  final List<FeedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing to explore yet.'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        return switch (items[i]) {
          PostFeedItem(:final post) => PostTile(
            post: post,
            onTap: () => Navigator.push(context, AppRoutes.post(post.id)),
          ),
          EventFeedItem(:final event) => _EventTile(
            event: event,
            onTap: () => Navigator.push(context, AppRoutes.event(event.id)),
          ),
        };
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = event.dateTime;
    return Semantics(
      button: true,
      label: event.title,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: eventGradient(event.id)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (date != null)
                  Text(
                    DateFormat('d MMM').format(date).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  event.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
