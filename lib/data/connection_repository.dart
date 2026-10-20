import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/local_cache.dart';
import '../core/providers.dart';
import '../models/connection.dart';
import '../models/json_helpers.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => ConnectionRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

class ConnectionRepository {
  ConnectionRepository(this._api, this._cache);

  final ApiClient _api;
  final LocalCache _cache;

  String _key(int userId) => 'connections:$userId';

  UserConnections? cachedFor(int userId) {
    final cached = asMap(_cache.read(_key(userId)));
    return cached == null ? null : UserConnections.fromJson(cached);
  }

  Future<UserConnections> fetchFor(int userId) async {
    final data = asMap(await _api.get('/connections/user/$userId'))!;
    await _cache.write(_key(userId), data);
    return UserConnections.fromJson(data);
  }

  Future<int> acceptedCount(int userId) async {
    final data = asMap(await _api.get('/connections/user/$userId/accepted'));
    return asInt(data?['count']);
  }

  Future<ConnectionStatus> statusBetween(int me, int other) async {
    final data = asMap(await _api.get('/connections/status/$me/$other'));
    return ConnectionStatus.parse(data?['status']);
  }

  /// The connection row between two users, or null when there is none.
  Future<Connection?> between(int me, int other) async {
    try {
      final data = asMap(await _api.get('/connections/between/$me/$other'));
      return data == null ? null : Connection.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> request(int receiverId) =>
      _api.post('/connections', body: {'receiver_id': receiverId});

  Future<void> respond(int connectionId, {required bool accept}) => _api.put(
    '/connections/respond',
    body: {'connectionId': connectionId, 'accept': accept},
  );

  /// Cancels a pending request or removes an accepted connection.
  Future<void> remove(int connectionId) =>
      _api.delete('/connections/$connectionId');
}
