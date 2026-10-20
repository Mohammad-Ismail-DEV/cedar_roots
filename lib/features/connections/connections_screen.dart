import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/connection.dart';
import '../../models/user.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'connections_provider.dart';

/// Connections of [userId] (default: the signed-in user). Requests are private,
/// so that tab only appears on your own list.
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key, this.userId, this.initialTab = 0});

  final int? userId;

  /// 0 for Connections, 1 for Requests (own connections only).
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return const SignInRequired(
        title: 'Connections',
        message: 'Log in to see connections.',
      );
    }
    final target = userId ?? me;
    return _Connections(
      userId: target,
      isMine: target == me,
      initialTab: initialTab,
    );
  }
}

class _Connections extends ConsumerStatefulWidget {
  const _Connections({
    required this.userId,
    required this.isMine,
    required this.initialTab,
  });

  final int userId;
  final bool isMine;
  final int initialTab;

  @override
  ConsumerState<_Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends ConsumerState<_Connections>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabs = TabController(
    length: widget.isMine ? 2 : 1,
    initialIndex: widget.isMine ? widget.initialTab.clamp(0, 1) : 0,
    vsync: this,
  );
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  // Refresh when coming back from a profile (a request may have been answered there).
  @override
  void didPopNext() => _refresh();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.read(connectionsProvider(widget.userId).notifier).refresh();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        bottom:
            widget.isMine
                ? TabBar(
                  controller: _tabs,
                  indicatorColor: Theme.of(context).colorScheme.onSurface,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  unselectedLabelColor: context.palette.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  dividerColor: context.palette.border,
                  tabs: const [Tab(text: 'Connections'), Tab(text: 'Requests')],
                )
                : null,
      ),
      body: connections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () =>
                            ref.invalidate(connectionsProvider(widget.userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data:
            (data) => TabBarView(
              controller: _tabs,
              children: [
                _ConnectionsTab(
                  me: widget.userId,
                  data: data,
                  onRefresh: _refresh,
                ),
                if (widget.isMine)
                  _RequestsTab(
                    me: widget.userId,
                    data: data,
                    onRefresh: _refresh,
                  ),
              ],
            ),
      ),
    );
  }
}

/// Search box plus debounced "Suggestions" (people not yet in the exclude set).
mixin _SuggestionSearch<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final search = TextEditingController();
  Timer? _debounce;
  String query = '';
  String suggestionQuery = '';

  void onSearchChanged(String text) {
    setState(() => query = text.trim().toLowerCase());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => suggestionQuery = text.trim());
    });
  }

  void disposeSearch() {
    _debounce?.cancel();
    search.dispose();
  }

  Widget searchField(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      controller: search,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
      ),
    ),
  );

  List<Widget> suggestions(Set<int> exclude) {
    if (suggestionQuery.isEmpty) return const [];
    final users =
        ref.watch(userSuggestionsProvider(suggestionQuery)).valueOrNull;
    // Never suggest yourself, even when your name partly matches the search.
    final me = ref.read(currentUserIdProvider);
    final shown =
        users?.where((u) => u.id != me && !exclude.contains(u.id)).toList() ??
        const [];
    if (shown.isEmpty) return const [];

    return [
      const _Heading('Suggestions'),
      for (final user in shown)
        _UserTile(
          user: user,
          color: Colors.green,
          onTap: () {
            Navigator.push(context, AppRoutes.profile(user.id));
            setState(() => suggestionQuery = '');
          },
        ),
    ];
  }
}

class _ConnectionsTab extends ConsumerStatefulWidget {
  const _ConnectionsTab({
    required this.me,
    required this.data,
    required this.onRefresh,
  });

  final int me;
  final UserConnections data;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends ConsumerState<_ConnectionsTab>
    with _SuggestionSearch {
  @override
  void dispose() {
    disposeSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = <User>[
      for (final c in widget.data.accepted)
        if (c.other(widget.me) case final user?
            when user.name.toLowerCase().contains(query))
          user,
    ];
    final existing = {
      for (final c in widget.data.accepted) c.other(widget.me)?.id ?? -1,
    };

    return Column(
      children: [
        searchField('Search connections...'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final user in matches)
                  _UserTile(
                    user: user,
                    color: Colors.green,
                    onTap:
                        () =>
                            Navigator.push(context, AppRoutes.profile(user.id)),
                  ),
                if (matches.isEmpty) const _Empty('No matching connections.'),
                ...suggestions(existing),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab({
    required this.me,
    required this.data,
    required this.onRefresh,
  });

  final int me;
  final UserConnections data;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab>
    with _SuggestionSearch {
  @override
  void dispose() {
    disposeSearch();
    super.dispose();
  }

  Future<void> _respond(Connection connection, bool accept) async {
    try {
      await ref
          .read(connectionsProvider(widget.me).notifier)
          .respond(connection.id, accept: accept);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  bool _matches(User? user) =>
      user != null && user.name.toLowerCase().contains(query);

  @override
  Widget build(BuildContext context) {
    final incoming =
        widget.data.requests
            .where((c) => _matches(c.other(widget.me)))
            .toList();
    final outgoing =
        widget.data.outgoing
            .where((c) => _matches(c.other(widget.me)))
            .toList();
    final existing = {
      widget.me,
      for (final list in [
        widget.data.accepted,
        widget.data.requests,
        widget.data.outgoing,
      ])
        for (final c in list) c.other(widget.me)?.id ?? -1,
    };

    return Column(
      children: [
        searchField('Search requests...'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in incoming)
                  _UserTile(
                    user: c.other(widget.me)!,
                    color: Colors.grey,
                    onTap:
                        () => Navigator.push(
                          context,
                          AppRoutes.profile(c.other(widget.me)!.id),
                        ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconShadowButton(
                          icon: Icons.check,
                          tooltip: 'Accept',
                          color: Colors.green,
                          onTap: () => _respond(c, true),
                        ),
                        const SizedBox(width: 8),
                        _IconShadowButton(
                          icon: Icons.close,
                          tooltip: 'Reject',
                          color: Colors.red,
                          onTap: () => _respond(c, false),
                        ),
                      ],
                    ),
                  ),
                if (incoming.isEmpty)
                  const _Empty('No incoming requests found.'),
                if (outgoing.isNotEmpty) ...[
                  const _Heading('Outgoing Requests'),
                  for (final c in outgoing)
                    _UserTile(
                      user: c.other(widget.me)!,
                      color: Colors.grey,
                      subtitle: 'Pending approval',
                      onTap:
                          () => Navigator.push(
                            context,
                            AppRoutes.profile(c.other(widget.me)!.id),
                          ),
                    ),
                ],
                ...suggestions(existing),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final User user;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(
        name: user.name,
        blob: user.profilePicBlob,
        imageUrl: user.profilePic,
        backgroundColor: context.palette.avatarBg,
      ),
      title: Text(user.name, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _IconShadowButton extends StatelessWidget {
  const _IconShadowButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;

  /// Green means "accept" (filled with the accent colour); anything else is a quiet button.
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final primary = color == Colors.green;
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary ? scheme.primary : context.palette.inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              color: primary ? Colors.white : scheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    ),
  );
}
