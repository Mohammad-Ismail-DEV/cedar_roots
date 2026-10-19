import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/notification_repository.dart';
import '../../models/app_notification.dart';

/// The notification list: last known list first, then fresh, and it updates the
/// moment the server pushes a new notification over the socket.
final notificationsProvider = AsyncNotifierProvider.autoDispose<
  NotificationsNotifier,
  List<AppNotification>
>(NotificationsNotifier.new);

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<List<AppNotification>> build() async {
    final live = ref
        .read(socketClientProvider)
        .on('receive_notification')
        .listen((_) => unawaited(refresh().catchError((_) {})));
    ref.onDispose(live.cancel);

    final cached = _repo.cached();
    if (cached != null) {
      unawaited(refresh().catchError((_) {}));
      return cached;
    }
    return _repo.fetch();
  }

  /// Throws on failure so pull-to-refresh can report it; old data stays visible.
  Future<void> refresh() async {
    state = AsyncData(await _repo.fetch());
  }

  Future<void> markRead(int id) async {
    final before = state.valueOrNull;
    if (before == null) return;

    state = AsyncData([
      for (final n in before) n.id == id ? n.copyWith(isRead: true) : n,
    ]);
    try {
      await _repo.markRead(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    final before = state.valueOrNull;
    if (before == null) return;

    state = AsyncData(before.where((n) => n.id != id).toList());
    try {
      await _repo.delete(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
