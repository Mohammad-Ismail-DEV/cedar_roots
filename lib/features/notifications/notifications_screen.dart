import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/time_label.dart';
import '../../core/ui.dart';
import '../../models/app_notification.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../../shared/widgets/user_avatar.dart';
import '../connections/connections_provider.dart';
import '../connections/connections_screen.dart';
import 'notification_router.dart';
import 'notifications_provider.dart';

enum _Filter {
  all('All'),
  likes('Likes'),
  comments('Comments'),
  events('Events');

  const _Filter(this.label);
  final String label;

  bool matches(AppNotification n) {
    final type = n.routeType;
    return switch (this) {
      _Filter.all => true,
      _Filter.likes => type == 'like',
      _Filter.comments => type == 'comment',
      _Filter.events => type.contains('event'),
    };
  }
}

IconData _iconFor(String type) {
  if (type == 'like') return Icons.favorite_border;
  if (type == 'comment') return Icons.mode_comment_outlined;
  if (type == 'chat') return Icons.send_outlined;
  if (type.contains('event')) return Icons.calendar_month_outlined;
  if (type.contains('connection')) return Icons.person_add_alt_outlined;
  if (type.contains('organization')) return Icons.apartment_outlined;
  return Icons.notifications_none;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _Filter _filter = _Filter.all;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _markAllRead(List<AppNotification> list) async {
    final notifier = ref.read(notificationsProvider.notifier);
    for (final n in list.where((n) => !n.isRead)) {
      await _run(() => notifier.markRead(n.id));
    }
  }

  Future<void> _open(AppNotification n) async {
    final notifier = ref.read(notificationsProvider.notifier);
    if (!n.isRead) await _run(() => notifier.markRead(n.id));
    openNotificationTarget(type: n.routeType, data: n.data);
  }

  Widget _requestsRow(int me) {
    final connections = ref.watch(connectionsProvider(me)).valueOrNull;
    final requests = connections?.requests ?? const [];
    if (requests.isEmpty || _filter != _Filter.all) {
      return const SizedBox.shrink();
    }

    final first = requests.first.other(me);
    final others = requests.length - 1;
    final palette = context.palette;

    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ConnectionsScreen(initialTab: 1),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            UserAvatar(
              name: first?.name ?? '?',
              imageUrl: first?.profilePic,
              blob: first?.profilePicBlob,
              radius: 22,
              backgroundColor: palette.avatarBg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection requests',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${first?.name ?? 'Someone'}'
                    '${others > 0 ? ' + $others ${others == 1 ? 'other' : 'others'}' : ''}',
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return const SignInRequired(
        title: 'Notifications',
        message: 'Log in to see notifications.',
      );
    }

    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final all = notifications.valueOrNull ?? const <AppNotification>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (all.any((n) => !n.isRead))
            TextButton(
              onPressed: () => _markAllRead(all),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (list) {
          final shown = list.where(_filter.matches).toList();
          return RefreshIndicator(
            onRefresh: () => _run(notifier.refresh),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _Filter.values) ...[
                          ChoiceChip(
                            label: Text(f.label),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                            showCheckmark: false,
                            backgroundColor: palette.inputBg,
                            selectedColor: scheme.onSurface,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            labelStyle: TextStyle(
                              color:
                                  _filter == f
                                      ? scheme.surface
                                      : scheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                _requestsRow(me),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                  ),
                for (final n in shown)
                  Container(
                    color:
                        n.isRead
                            ? null
                            : scheme.primary.withValues(alpha: 0.07),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _open(n),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: palette.avatarBg,
                                    child: Icon(
                                      _iconFor(n.routeType),
                                      size: 20,
                                      color: palette.avatarInk,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: n.message),
                                          if (n.createdAt != null)
                                            TextSpan(
                                              text:
                                                  '  ${shortAgo(n.createdAt)}',
                                              style: TextStyle(
                                                color: palette.muted,
                                              ),
                                            ),
                                        ],
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          IconButton(
                            tooltip: 'Mark as read',
                            icon: Icon(Icons.done, color: palette.muted),
                            onPressed:
                                () => _run(() => notifier.markRead(n.id)),
                          ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: Icon(
                            Icons.delete_outline,
                            color: palette.muted,
                          ),
                          onPressed: () => _run(() => notifier.delete(n.id)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
