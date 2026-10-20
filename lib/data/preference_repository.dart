import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../models/json_helpers.dart';
import '../models/preferences.dart';

final preferenceRepositoryProvider = Provider<PreferenceRepository>(
  (ref) => PreferenceRepository(ref.watch(apiClientProvider)),
);

class PreferenceRepository {
  PreferenceRepository(this._api);

  final ApiClient _api;

  Future<NotificationPreferences> get() async =>
      NotificationPreferences.fromJson(
        asMap(await _api.get('/users/me/preferences')) ?? const {},
      );

  Future<NotificationPreferences> update({
    bool? pushEnabled,
    bool? eventReminders,
  }) async => NotificationPreferences.fromJson(
    asMap(
          await _api.put(
            '/users/me/preferences',
            body: {
              if (pushEnabled != null) 'push_enabled': pushEnabled,
              if (eventReminders != null) 'event_reminders': eventReminders,
            },
          ),
        ) ??
        const {},
  );
}
