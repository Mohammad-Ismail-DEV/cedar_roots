import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/image_url.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/connection.dart';
import '../../models/post.dart';
import '../../shared/widgets/post_tile.dart';
import '../../shared/widgets/ring_avatar.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../../shared/widgets/user_avatar.dart';
import '../feed/saved_posts.dart';
import '../organizations/organization_providers.dart';
import '../settings/settings_screen.dart';
import '../shell/app_routes.dart';
import 'edit_profile_screen.dart';
import 'profile_actions.dart';
import 'profile_provider.dart';

/// A user's profile. With no [userId] it shows the signed-in user's own profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return const SignInRequired(message: 'Log in to see your profile.');
    }
    return _Profile(userId: userId ?? me, myUserId: me);
  }
}

class _Profile extends ConsumerStatefulWidget {
  const _Profile({required this.userId, required this.myUserId});

  final int userId;
  final int myUserId;

  @override
  ConsumerState<_Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<_Profile> {
  Offset? _pointerStart;

  bool get _showSaved => _isMine && ref.watch(savedTabProvider);
  void _setSaved(bool value) =>
      ref.read(savedTabProvider.notifier).state = value;

  /// A clear sideways swipe flips between Posts and Saved on my own profile.
  void _onPointerUp(PointerUpEvent event) {
    final start = _pointerStart;
    _pointerStart = null;
    if (start == null || !_isMine) return;
    final dx = event.position.dx - start.dx;
    final dy = event.position.dy - start.dy;
    if (dx.abs() < 70 || dx.abs() < dy.abs() * 2) return;
    final saved = ref.read(savedTabProvider);
    if (dx < 0 && !saved) _setSaved(true);
    if (dx > 0 && saved) _setSaved(false);
  }

  int get _userId => widget.userId;
  bool get _isMine => widget.userId == widget.myUserId;

  ProfileNotifier get _notifier => ref.read(profileProvider(_userId).notifier);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _showAvatar(String? url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child:
                        url != null && url.isNotEmpty
                            ? CachedNetworkImage(
                              httpHeaders: imageHeaders,
                              imageUrl: sizedImageUrl(
                                url,
                                logicalWidth: MediaQuery.sizeOf(ctx).width,
                                pixelRatio: MediaQuery.devicePixelRatioOf(ctx),
                              ),
                              fit: BoxFit.contain,
                            )
                            : const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Close',
                            color: Colors.white,
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          if (_isMine)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                changeProfilePicture(context, ref, _userId);
                              },
                              child: const Text(
                                'Change',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  List<Widget> _connectionButtons(ProfileData data) {
    Widget button(String label, VoidCallback onTap, {bool danger = false}) =>
        Expanded(
          child: ShadowButton(
            label: label,
            color: danger ? Colors.red : null,
            onTap: onTap,
          ),
        );

    final chat = button(
      'Message',
      () => Navigator.push(
        context,
        AppRoutes.chat(userId: _userId, name: data.user.name),
      ),
    );

    return switch (data.status) {
      ConnectionStatus.accepted => [
        button(
          'Remove Connection',
          () => _run(_notifier.disconnect),
          danger: true,
        ),
        const SizedBox(width: 8),
        chat,
      ],
      ConnectionStatus.pendingSent => [
        button(
          'Cancel Request',
          () => _run(_notifier.disconnect),
          danger: true,
        ),
      ],
      ConnectionStatus.pendingReceived => [
        button('Accept', () => _run(() => _notifier.respond(accept: true))),
        const SizedBox(width: 8),
        button(
          'Reject',
          () => _run(() => _notifier.respond(accept: false)),
          danger: true,
        ),
      ],
      ConnectionStatus.none => [
        button('Connect', () => _run(_notifier.connect)),
      ],
    };
  }

  Widget _stat(String value, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _highlights() {
    final orgs = ref.watch(myOrganizationsProvider(_userId)).valueOrNull ?? [];
    if (orgs.isEmpty && !_isMine) return const SizedBox.shrink();
    final palette = context.palette;

    Widget item(Widget circle, String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            circle,
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 98,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        children: [
          for (final org in orgs)
            item(
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: UserAvatar(
                  name: org.name,
                  imageUrl: org.logo,
                  blob: org.logoBlob,
                  radius: 28,
                  backgroundColor: palette.avatarBg,
                ),
              ),
              org.name,
              () => Navigator.push(context, AppRoutes.organization(org.id)),
            ),
          if (_isMine)
            item(
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
              'New',
              () => Navigator.push(context, AppRoutes.organizationForm()),
            ),
        ],
      ),
    );
  }

  Widget _tab(
    IconData icon,
    String tooltip,
    bool selected,
    VoidCallback onTap,
  ) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            semanticLabel: tooltip,
            color: selected ? color : context.palette.muted,
          ),
        ),
      ),
    );
  }

  Widget _header(ProfileData data) {
    final user = data.user;
    final palette = context.palette;
    final orgCount =
        ref.watch(myOrganizationsProvider(_userId)).valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showAvatar(user.profilePic),
                child: RingAvatar(
                  name: user.name,
                  imageUrl: user.profilePic,
                  blob: user.profilePicBlob,
                  radius: 40,
                  ringed: _isMine || data.status == ConnectionStatus.accepted,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${data.posts.length}', 'Posts'),
                    _stat(
                      '${data.connectionsCount}',
                      'Connections',
                      onTap:
                          () => Navigator.push(
                            context,
                            AppRoutes.connections(_userId),
                          ),
                    ),
                    _stat('$orgCount', 'Organizations'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty)
                Text(user.bio!, style: const TextStyle(height: 1.35)),
              if (user.location != null && user.location!.isNotEmpty)
                Text(
                  user.location!,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child:
              _isMine
                  ? Row(
                    children: [
                      Expanded(
                        child: ShadowButton(
                          label: 'Edit profile',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShadowButton(
                          label: 'Manage Organizations',
                          color: Colors.red,
                          onTap:
                              () => Navigator.push(
                                context,
                                AppRoutes.organizations(_userId),
                              ),
                        ),
                      ),
                    ],
                  )
                  : Row(children: _connectionButtons(data)),
        ),
        _highlights(),
        Divider(color: palette.border),
        if (_isMine)
          Row(
            children: [
              _tab(
                Icons.grid_on_outlined,
                'Posts',
                !_showSaved,
                () => _setSaved(false),
              ),
              _tab(
                Icons.bookmark_border,
                'Saved',
                _showSaved,
                () => _setSaved(true),
              ),
            ],
          )
        else
          Row(children: [_tab(Icons.grid_on_outlined, 'Posts', true, () {})]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider(_userId));

    return profile.when(
      loading:
          () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(profileProvider(_userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: _loaded,
    );
  }

  Widget _loaded(ProfileData data) {
    final saved =
        _isMine && _showSaved
            ? ref.watch(savedPostObjectsProvider)
            : const AsyncData<List<Post>>([]);
    final List<Post> posts =
        _isMine && _showSaved ? (saved.valueOrNull ?? []) : data.posts;
    final emptyText =
        _showSaved ? 'Posts you save will appear here.' : 'No posts yet.';

    return Scaffold(
      appBar: AppBar(
        title: Text(data.user.name),
        actions: [
          if (_isMine)
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.menu),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
            ),
        ],
      ),
      body: Listener(
        onPointerDown: (e) => _pointerStart = e.position,
        onPointerCancel: (_) => _pointerStart = null,
        onPointerUp: _onPointerUp,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider(_userId)),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(data)),
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child:
                          saved.isLoading && _showSaved
                              ? const CircularProgressIndicator()
                              : Text(
                                emptyText,
                                style: TextStyle(color: context.palette.muted),
                              ),
                    ),
                  ),
                )
              else
                PostGrid(
                  posts: posts,
                  onOpen:
                      (post) =>
                          Navigator.push(context, AppRoutes.post(post.id)),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
