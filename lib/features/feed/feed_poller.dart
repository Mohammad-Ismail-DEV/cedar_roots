import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import 'feed_provider.dart';

const feedPollInterval = Duration(seconds: 15);

/// Quietly re-checks the feed while the app is open and someone is signed in, so new posts from
/// connections appear without pulling to refresh. Paused while the app is in the background and
/// catches up as soon as it returns. Watch once near the app root.
final feedPollerProvider = Provider<void>((ref) {
  Timer? timer;

  void start() {
    timer?.cancel();
    timer = Timer.periodic(feedPollInterval, (_) {
      if (ref.read(currentUserIdProvider) == null) return;
      ref.read(feedProvider.notifier).poll();
    });
  }

  final lifecycle = AppLifecycleListener(
    onResume: () {
      start();
      if (ref.read(currentUserIdProvider) != null) {
        ref.read(feedProvider.notifier).poll();
      }
    },
    onInactive: () => timer?.cancel(),
  );

  start();
  ref.onDispose(() {
    timer?.cancel();
    lifecycle.dispose();
  });
});
