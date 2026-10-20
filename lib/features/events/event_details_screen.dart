import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../shared/widgets/user_avatar.dart';
import 'event_details_provider.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shadow_button.dart';
import 'event_style.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  const EventDetailsScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  final _announcement = TextEditingController();

  EventDetailsNotifier get _notifier =>
      ref.read(eventDetailsProvider(widget.eventId).notifier);

  @override
  void dispose() {
    _announcement.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _postAnnouncement() async {
    final message = _announcement.text.trim();
    if (message.isEmpty) return;
    await _run(() async {
      await _notifier.announce(message);
      _announcement.clear();
    });
  }

  String _formatDateTime(DateTime? date) =>
      date == null
          ? 'Unknown time'
          : DateFormat('MMMM d, y • h:mm a').format(date);

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(eventDetailsProvider(widget.eventId));
    final signedIn = ref.watch(currentUserIdProvider) != null;

    return details.when(
      loading:
          () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          eventDetailsProvider(widget.eventId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: (data) => _content(data, signedIn),
    );
  }

  Widget _joinControl(EventDetails data, bool signedIn) {
    if (!signedIn) {
      return Text(
        'Login to interact with this event.',
        style: TextStyle(color: context.palette.muted),
      );
    }
    if (data.isOrgMember) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'You organise this event.',
          style: TextStyle(color: context.palette.muted, fontSize: 13),
        ),
      );
    }

    return data.isParticipant
        ? ShadowButton(
          label: 'Leave Event',
          color: Colors.red,
          onTap: () => _run(_notifier.leave),
        )
        : ShadowButton(label: 'Join Event', onTap: () => _run(_notifier.join));
  }

  Widget _content(EventDetails data, bool signedIn) {
    final event = data.event;
    final org = event.organization;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: RefreshIndicator(
        onRefresh: _notifier.reload,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(gradient: eventGradient(event.id)),
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(14),
              child:
                  event.dateTime == null
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
                              DateFormat('d').format(event.dateTime!),
                              style: const TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM',
                              ).format(event.dateTime!).toUpperCase(),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        name: org?.name ?? '?',
                        blob: org?.logoBlob,
                        imageUrl: org?.logo,
                        radius: 24,
                        backgroundColor: context.palette.avatarBg,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        org?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(event.description ?? ''),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(event.dateTime),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (event.location != null && event.location!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.location!)),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _joinControl(data, signedIn),
                  const SizedBox(height: 24),
                  const Text(
                    'Announcements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (data.canAnnounce) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _announcement,
                      decoration: InputDecoration(
                        filled: true,
                        hintText: 'Write an announcement...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _postAnnouncement,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (_) => _postAnnouncement(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final a in data.announcements)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.message),
                      subtitle: Text(_formatDateTime(a.createdAt)),
                      leading: const Icon(Icons.campaign_outlined),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
