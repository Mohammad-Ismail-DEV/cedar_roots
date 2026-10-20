import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/preference_repository.dart';
import '../../models/preferences.dart';

/// Push and reminder switches, stored on the server so they follow you to a new phone.
final preferencesProvider = AsyncNotifierProvider.autoDispose<
  PreferencesNotifier,
  NotificationPreferences
>(PreferencesNotifier.new);

class PreferencesNotifier
    extends AutoDisposeAsyncNotifier<NotificationPreferences> {
  PreferenceRepository get _repo => ref.read(preferenceRepositoryProvider);

  @override
  Future<NotificationPreferences> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const NotificationPreferences();
    }
    return _repo.get();
  }

  Future<void> setPushEnabled(bool on) => _change(
    (p) => p.copyWith(pushEnabled: on),
    () => _repo.update(pushEnabled: on),
  );

  Future<void> setEventReminders(bool on) => _change(
    (p) => p.copyWith(eventReminders: on),
    () => _repo.update(eventReminders: on),
  );

  /// Flips the switch on screen straight away and puts it back if the server says no.
  Future<void> _change(
    NotificationPreferences Function(NotificationPreferences) apply,
    Future<NotificationPreferences> Function() save,
  ) async {
    final before = state.valueOrNull ?? const NotificationPreferences();
    state = AsyncData(apply(before));
    try {
      state = AsyncData(await save());
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
