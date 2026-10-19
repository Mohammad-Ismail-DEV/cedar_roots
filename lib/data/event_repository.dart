import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/local_cache.dart';
import '../core/providers.dart';
import '../models/event.dart';
import '../models/json_helpers.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

class EventRepository {
  EventRepository(this._api, this._cache);

  final ApiClient _api;
  final LocalCache _cache;

  static const _listKey = 'events';

  List<Event>? cachedEvents() {
    final cached = _cache.read(_listKey);
    return cached == null
        ? null
        : asMapList(cached).map(Event.fromJson).toList();
  }

  Future<List<Event>> fetchEvents({int? userId}) async {
    final data = await _api.get('/events', query: {'user_id': userId});
    final list = asMapList(data);
    await _cache.write(_listKey, list.take(30).toList());
    return list.map(Event.fromJson).toList();
  }

  Future<Event> getById(int id) async =>
      Event.fromJson(asMap(await _api.get('/events/$id'))!);

  Future<void> create({
    required String title,
    required int organizationId,
    required DateTime dateTime,
    String? description,
    String? location,
    List<int> collaborators = const [],
  }) => _api.post(
    '/events',
    body: {
      'title': title,
      'organization_id': organizationId,
      'date_time': dateTime.toUtc().toIso8601String(),
      'description': description,
      'location': location,
      'collaborators': collaborators,
    },
  );

  Future<void> join(int eventId) => _api.post('/events/$eventId/join');

  Future<List<EventParticipant>> participants(int eventId) async {
    final data = await _api.get('/events/$eventId/participants');
    return asMapList(data).map(EventParticipant.fromJson).toList();
  }

  Future<List<Announcement>> announcements(int eventId) async {
    final data = await _api.get('/announcements/$eventId');
    return asMapList(data).map(Announcement.fromJson).toList();
  }

  Future<void> announce(int eventId, String message) => _api.post(
    '/announcements',
    body: {'event_id': eventId, 'message': message},
  );
}
