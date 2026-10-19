import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/local_cache.dart';
import '../core/providers.dart';
import '../models/app_notification.dart';
import '../models/json_helpers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

class NotificationRepository {
  NotificationRepository(this._api, this._cache);

  final ApiClient _api;
  final LocalCache _cache;

  static const _key = 'notifications';

  List<AppNotification>? cached() {
    final cached = _cache.read(_key);
    return cached == null
        ? null
        : asMapList(cached).map(AppNotification.fromJson).toList();
  }

  Future<List<AppNotification>> fetch() async {
    final list = asMapList(await _api.get('/notifications'));
    await _cache.write(_key, list.take(50).toList());
    return list.map(AppNotification.fromJson).toList();
  }

  Future<void> markRead(int id) => _api.put('/notifications/$id/read');

  Future<void> delete(int id) => _api.delete('/notifications/$id');
}
