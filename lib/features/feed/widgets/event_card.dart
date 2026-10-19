import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event.dart';
import '../../../shared/widgets/user_avatar.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final org = event.organization;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.fromLTRB(0, 1.5, 0, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: org?.name ?? '?',
                    blob: org?.logoBlob,
                    imageUrl: org?.logo,
                    radius: 16,
                    backgroundColor: Colors.grey[400]!,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    org?.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              if (event.dateTime != null)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM d, yyyy • hh:mm a',
                      ).format(event.dateTime!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              if (event.location != null && event.location!.isNotEmpty)
                Text(
                  event.location!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
