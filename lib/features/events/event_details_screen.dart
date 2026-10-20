import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../shared/widgets/user_avatar.dart';
import 'event_details_provider.dart';

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
      return const Text(
        'Login to interact with this event.',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      );
    }
    if (data.isOrgMember) return const SizedBox.shrink();

    return data.isParticipant
        ? ElevatedButton(
          onPressed: () => _run(_notifier.leave),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text(
            'Leave Event',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        )
        : ElevatedButton(
          onPressed: () => _run(_notifier.join),
          child: const Text('Join Event'),
        );
  }

  Widget _content(EventDetails data, bool signedIn) {
    final event = data.event;
    final org = event.organization;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: RefreshIndicator(
        onRefresh: _notifier.reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                UserAvatar(
                  name: org?.name ?? '?',
                  blob: org?.logoBlob,
                  imageUrl: org?.logo,
                  radius: 24,
                  backgroundColor: Colors.grey[400]!,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event.description ?? ''),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(event.dateTime),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                  fillColor: Colors.white,
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
                title: Text(a.message),
                subtitle: Text(_formatDateTime(a.createdAt)),
                leading: const Icon(Icons.campaign_outlined),
              ),
          ],
        ),
      ),
    );
  }
}
