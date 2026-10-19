import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'core/providers.dart';
import 'features/notifications/push_handler.dart';
import 'features/shell/nav_bar.dart';

class CedarRootsApp extends ConsumerWidget {
  const CedarRootsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both follow the signed-in session for the whole app lifetime.
    ref.watch(socketLifecycleProvider);
    ref.watch(pushLifecycleProvider);

    return MaterialApp(
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      title: 'Cedar Roots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const NavBar(),
    );
  }
}
