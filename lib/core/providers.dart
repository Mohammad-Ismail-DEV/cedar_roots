import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'config.dart';
import 'local_cache.dart';
import 'session.dart';
import 'socket_client.dart';

/// Overridden in main() with the instance loaded before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(ref.watch(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: AppConfig.apiUrl,
    tokenReader: () => ref.read(sessionProvider)?.token,
    onUnauthorized: () => ref.read(sessionProvider.notifier).signOut(),
  ),
);

final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient();
  ref.onDispose(client.disconnect);
  return client;
});

/// Whether the socket is currently connected (for "connecting..." banners).
final socketConnectedProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final socket = ref.watch(socketClientProvider);
  yield socket.isConnected;
  yield* socket.connection;
});

/// Keeps the socket connected exactly while someone is signed in.
/// Watch this once near the app root.
final socketLifecycleProvider = Provider<void>((ref) {
  final socket = ref.watch(socketClientProvider);
  ref.listen<Session?>(sessionProvider, (_, session) {
    if (session == null) {
      socket.disconnect();
    } else {
      socket.connect(
        url: AppConfig.socketUrl,
        token: session.token,
        userId: session.userId,
      );
    }
  }, fireImmediately: true);
});
