import 'package:flutter/material.dart';

/// Displays details about a specific event.
/// Later, this page will pull real data from Firestore using an event ID.
class EventDetailPage extends StatelessWidget {
  // The eventId lets us load specific event data later
  final String? eventId;

  const EventDetailPage({super.key, this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temporary info to confirm the page is working
            Text(
              'Event ID: ${eventId ?? '(none provided)'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Placeholder text — will be replaced with real event info later
            const Text('🎯 Title: (coming soon)'),
            const Text('📅 Date: (coming soon)'),
            const Text('📍 Location: (coming soon)'),
            const SizedBox(height: 12),
            const Text(
              '📝 Description:\nThis is where event details will go once we connect Firestore.',
            ),
          ],
        ),
      ),
    );
  }
}