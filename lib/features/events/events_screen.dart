import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/event.dart';
import '../../shared/widgets/user_avatar.dart';
import '../feed/feed_provider.dart';
import '../organizations/organization_providers.dart';
import '../shell/app_routes.dart';
import 'event_style.dart';

/// The Events tab: upcoming events from organizations, with one-tap RSVP.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _onlyGoing = false;

  Future<void> _refresh() async {
    try {
      await ref.read(feedProvider.notifier).refresh();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _toggle(Event event) async {
    if (ref.read(currentUserIdProvider) == null) {
      showSnack(context, 'Login to join events');
      return;
    }
    try {
      await ref
          .read(feedProvider.notifier)
          .setGoing(event.id, going: !event.isParticipant);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: palette.inputBg,
      selectedColor: scheme.onSurface,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? scheme.surface : scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final feed = ref.watch(feedProvider);
    final myOrgIds =
        me == null
            ? const <int>{}
            : {
              for (final org
                  in ref.watch(myOrganizationsProvider(me)).valueOrNull ??
                      const [])
                org.id,
            };

    final all = (feed.valueOrNull ?? const <FeedItem>[])
        .whereType<EventFeedItem>()
        .map((i) => i.event);
    final goingCount = all.where((e) => e.isParticipant).length;
    final events = all.where((e) => !_onlyGoing || e.isParticipant).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Events'), titleSpacing: 16),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(feedProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data:
            (_) => RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        _chip(
                          'All events',
                          !_onlyGoing,
                          () => setState(() => _onlyGoing = false),
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          'Going ($goingCount)',
                          _onlyGoing,
                          () => setState(() => _onlyGoing = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          _onlyGoing
                              ? 'No events on your list yet.'
                              : 'No events yet.',
                          style: TextStyle(color: context.palette.muted),
                        ),
                      ),
                    ),
                  for (final event in events)
                    _EventCard(
                      event: event,
                      canJoin: !myOrgIds.contains(event.organizationId),
                      onOpen:
                          () => Navigator.push(
                            context,
                            AppRoutes.event(event.id),
                          ),
                      onOpenOrg:
                          () => Navigator.push(
                            context,
                            AppRoutes.organization(event.organizationId),
                          ),
                      onToggle: () => _toggle(event),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.canJoin,
    required this.onOpen,
    required this.onOpenOrg,
    required this.onToggle,
  });

  final Event event;
  final bool canJoin;
  final VoidCallback onOpen;
  final VoidCallback onOpenOrg;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final org = event.organization;
    final date = event.dateTime;
    final scheme = Theme.of(context).colorScheme;
    final going = event.isParticipant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Container(
              height: 190,
              decoration: BoxDecoration(gradient: eventGradient(event.id)),
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(14),
              child:
                  date == null
                      ? null
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('d').format(date),
                              style: const TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFC13584),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onOpenOrg,
                  child: UserAvatar(
                    name: org?.name ?? '?',
                    imageUrl: org?.logo,
                    blob: org?.logoBlob,
                    radius: 18,
                    backgroundColor: palette.avatarBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          [
                            if (date != null)
                              DateFormat('EEE, MMM d • h:mm a').format(date),
                            if (event.location != null &&
                                event.location!.isNotEmpty)
                              event.location!,
                          ].join(' · '),
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                        Text(
                          '${org?.name ?? ''} · ${event.participantCount} attending',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (canJoin) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: onToggle,
                      style: TextButton.styleFrom(
                        backgroundColor:
                            going ? palette.inputBg : scheme.primary,
                        foregroundColor:
                            going ? scheme.onSurface : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(going ? 'Going' : 'RSVP'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
