import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/session.dart';
import '../../data/user_repository.dart';
import '../../models/json_helpers.dart';
import '../../models/presence.dart';

/// Whether one connection (the argument is their user id) is online, and when they were last
/// seen. Loaded once, then kept live by the server's `presence_changed` events.
final presenceProvider = NotifierProvider.autoDispose
    .family<PresenceNotifier, Presence, int>(PresenceNotifier.new);

class PresenceNotifier extends AutoDisposeFamilyNotifier<Presence, int> {
  @override
  Presence build(int arg) {
    if (ref.watch(currentUserIdProvider) == null) return Presence.unknown;

    final socket = ref.read(socketClientProvider);
    final live = socket.on('presence_changed').listen((data) {
      final map = asMap(data);
      if (map == null || asInt(map['userId']) != arg) return;
      state = Presence(
        online: map['online'] == true,
        lastSeenAt: asDate(map['last_seen_at']) ?? DateTime.now(),
      );
    });
    // Events sent while we were disconnected are not replayed, so ask again.
    final reconnected = socket.connection
        .where((connected) => connected)
        .listen((_) => unawaited(_load()));
    ref.onDispose(() {
      live.cancel();
      reconnected.cancel();
    });

    Future.microtask(_load);
    return Presence.unknown;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(userRepositoryProvider).presence(arg);
    } catch (_) {
      // Not a connection (or offline): show nothing rather than a wrong status.
    }
  }
}
