import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/session.dart';
import 'feed_provider.dart';

/// The socket announces every change, so this slow poll is only a safety net.
const feedPollInterval = Duration(minutes: 1);

/// Keeps the feed current without pulling to refresh. The server sends `feed_changed` whenever a
/// post or event is created, edited or deleted, and we re-check straight away (batching bursts).
/// We also re-check after a reconnect or coming back to the app, since events sent while we were
/// away are not replayed, and on a slow timer in case a message is ever lost.
/// Only rebuilds the list when something actually differs. Watch once near the app root.
final feedPollerProvider = Provider<void>((ref) {
  final socket = ref.watch(socketClientProvider);
  Timer? timer;
  Timer? batch;

  void check() {
    if (ref.read(currentUserIdProvider) == null) return;
    ref.read(feedProvider.notifier).poll();
  }

  void checkSoon() {
    batch?.cancel();
    batch = Timer(const Duration(milliseconds: 400), check);
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(feedPollInterval, (_) => check());
  }

  final subscriptions = [
    socket.on('feed_changed').listen((_) => checkSoon()),
    socket.connection
        .where((connected) => connected)
        .listen((_) => checkSoon()),
  ];

  final lifecycle = AppLifecycleListener(
    onResume: () {
      startTimer();
      check();
    },
    onInactive: () => timer?.cancel(),
  );

  startTimer();
  ref.onDispose(() {
    timer?.cancel();
    batch?.cancel();
    lifecycle.dispose();
    for (final s in subscriptions) {
      s.cancel();
    }
  });
});
