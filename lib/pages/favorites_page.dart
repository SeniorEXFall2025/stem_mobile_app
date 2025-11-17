import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_details.dart';

/// Favorites screen lives under the bottom nav.
/// It has two tabs:
///  - Saved      → events the user bookmarked with the star icon
///  - Registered → events the user registered for from the details page
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Saved'),
              Tab(text: 'Registered'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SavedTab(),
            _RegisteredTab(),
          ],
        ),
      ),
    );
  }
}

/// Shows the events the user has saved (bookmarked).
/// Data is stored under:
///   users/{uid}/favorites/{eventId}
class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Sign in to save events.'),
      );
    }

    final favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: favoritesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No saved events yet.\nTap the star on an event to save it.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final eventData =
                Map<String, dynamic>.from(data['eventData'] ?? {});
            final eventId = (data['eventId'] as String?) ?? doc.id;

            final title = eventData['title'] ?? 'Untitled event';
            final city = eventData['city'] ?? 'No city';
            final dateStr = eventData['date'] as String?;
            String dateLabel = 'Date TBD';

            if (dateStr != null) {
              try {
                final dt = DateTime.parse(dateStr);
                dateLabel =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              } catch (_) {
                // If parsing fails, leave the default
              }
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(title),
                subtitle: Text('$dateLabel • $city'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsPage(
                        eventId: eventId,
                        eventData: eventData,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Shows the events the user has registered for.
/// Data is stored under:
///   users/{uid}/registrations/{eventId}
class _RegisteredTab extends StatelessWidget {
  const _RegisteredTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Sign in to register for events.'),
      );
    }

    final registrationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registrations')
        .orderBy('registeredAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: registrationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have not registered for any events yet.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final eventData =
                Map<String, dynamic>.from(data['eventData'] ?? {});
            final eventId = (data['eventId'] as String?) ?? doc.id;

            final title = eventData['title'] ?? 'Untitled event';
            final city = eventData['city'] ?? 'No city';
            final dateStr = eventData['date'] as String?;
            String dateLabel = 'Date TBD';

            if (dateStr != null) {
              try {
                final dt = DateTime.parse(dateStr);
                dateLabel =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              } catch (_) {
                // If parsing fails, leave the default
              }
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(title),
                subtitle: Text('$dateLabel • $city'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsPage(
                        eventId: eventId,
                        eventData: eventData,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
