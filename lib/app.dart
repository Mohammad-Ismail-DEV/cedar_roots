import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/deep_links.dart';
import 'core/navigation.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'core/theme_mode.dart';
import 'features/chat/delivery_receipts.dart';
import 'features/feed/feed_poller.dart';
import 'features/feed/feed_provider.dart';
import 'features/feed/live_post_updates.dart';
import 'features/notifications/push_handler.dart';
import 'features/shell/nav_bar.dart';
import 'shared/widgets/splash_loader.dart';

class CedarRootsApp extends ConsumerWidget {
  const CedarRootsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both follow the signed-in session for the whole app lifetime.
    ref.watch(socketLifecycleProvider);
    ref.watch(pushLifecycleProvider);
    ref.watch(deliveryReceiptsProvider);
    ref.watch(livePostUpdatesProvider);
    ref.watch(feedPollerProvider);
    ref.watch(deepLinksProvider);

    return MaterialApp(
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      title: 'Cedar Roots',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: SplashGate(
        ready: !ref.watch(feedProvider).isLoading,
        child: const NavBar(),
      ),
    );
  }
}
