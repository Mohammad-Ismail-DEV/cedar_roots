import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/event_repository.dart';
import '../../data/organization_repository.dart';
import '../../models/event.dart';
import '../../models/organization.dart';

class EventDetails {
  const EventDetails({
    required this.event,
    required this.announcements,
    required this.isParticipant,
    this.myRole,
  });

  final Event event;
  final List<Announcement> announcements;

  /// Joined (or invited) as an attendee.
  final bool isParticipant;

  /// My role in the organization hosting the event, if I belong to it.
  final OrgRole? myRole;

  bool get isOrgMember => myRole != null;
  bool get canAnnounce => myRole?.canManage ?? false;
}

/// An event with its announcements and what the signed-in user may do with it.
final eventDetailsProvider = AsyncNotifierProvider.autoDispose
    .family<EventDetailsNotifier, EventDetails, int>(EventDetailsNotifier.new);

class EventDetailsNotifier
    extends AutoDisposeFamilyAsyncNotifier<EventDetails, int> {
  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<EventDetails> build(int arg) => _load();

  Future<EventDetails> _load() async {
    final me = ref.watch(currentUserIdProvider);
    final (event, announcements) =
        await (_repo.getById(arg), _repo.announcements(arg)).wait;

    var isParticipant = false;
    OrgRole? myRole;
    if (me != null) {
      final (participants, members) =
          await (
            _repo.participants(arg),
            ref
                .read(organizationRepositoryProvider)
                .members(event.organizationId),
          ).wait;
      isParticipant = participants.any((p) => p.userId == me);
      for (final m in members) {
        if (m.userId == me) myRole = m.role;
      }
    }

    return EventDetails(
      event: event,
      announcements: announcements,
      isParticipant: isParticipant,
      myRole: myRole,
    );
  }

  Future<void> reload() async {
    state = AsyncData(await _load());
  }

  Future<void> join() async {
    await _repo.join(arg);
    await reload();
  }

  Future<void> leave() async {
    await _repo.leave(arg);
    await reload();
  }

  Future<void> announce(String message) async {
    await _repo.announce(arg, message);
    await reload();
  }
}
