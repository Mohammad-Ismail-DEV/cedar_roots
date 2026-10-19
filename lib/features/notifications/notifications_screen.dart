import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../models/app_notification.dart';
import '../../shared/widgets/sign_in_required.dart';
import 'notification_router.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserIdProvider) == null) {
      return const SignInRequired(
        title: 'Notifications',
        message: 'Log in to see notifications.',
      );
    }

    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
        data:
            (list) =>
                list.isEmpty
                    ? const Center(child: Text('No notifications'))
                    : RefreshIndicator(
                      onRefresh: () => _run(context, notifier.refresh),
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final n = list[index];
                          return ListTile(
                            tileColor:
                                n.isRead ? Colors.grey[200] : Colors.white,
                            title: Text(n.message),
                            subtitle: Text(n.type),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!n.isRead)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.done,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Mark as read',
                                    onPressed:
                                        () => _run(
                                          context,
                                          () => notifier.markRead(n.id),
                                        ),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed:
                                      () => _run(
                                        context,
                                        () => notifier.delete(n.id),
                                      ),
                                ),
                              ],
                            ),
                            onTap: () => _open(context, notifier, n),
                          );
                        },
                      ),
                    ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    NotificationsNotifier notifier,
    AppNotification n,
  ) async {
    if (!n.isRead) await _run(context, () => notifier.markRead(n.id));
    openNotificationTarget(type: n.routeType, data: n.data);
  }
}
