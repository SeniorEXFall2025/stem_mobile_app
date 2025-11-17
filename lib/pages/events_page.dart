import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'event_details.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String? userRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snap =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final role = snap.data()?["role"];
      print("Loaded user role: $role"); // debug log
      setState(() {
        userRole = role?.toString().toLowerCase();
        _loadingRole = false;
      });
    } else {
      setState(() => _loadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Adaptive color for AppBar text/icons (white in dark mode, dark blue in light mode)
    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    // Adaptive background color for the AppBar (deep blue in dark mode, white in light mode)
    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;

    // Accent color used for titles, chips, and buttons (always dark blue)
    final Color accentColor = curiousBlue.shade900;

    return Scaffold(
      // Ensure the scaffold background is the theme's default (dark975 or white)
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("STEM Events"),
        // Use adaptive colors for AppBar
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("events")
            .orderBy("date")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No events available yet.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index]; // Get the document snapshot
              final data = doc.data() as Map<String, dynamic>;

              final title = data["title"] ?? "Untitled Event";
              final description = data["description"] ?? "No description";
              final dateStr = data["date"];
              final location = data["city"] ?? "No location";
              final topics = List<String>.from(data["topics"] ?? []);

              String formattedDate = dateStr ?? "TBD";
              if (dateStr != null) {
                try {
                  final parsedDate = DateTime.parse(dateStr);
                  formattedDate = DateFormat.yMMMEd().format(parsedDate);
                } catch (_) {}
              }

              // Determine card background color based on theme
              final cardBackgroundColor = theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05) // Subtle dark gray
                  : Colors.white; // White in light mode

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: cardBackgroundColor, // Set base card color
                // Wrap content in InkWell for tapping
                child: InkWell(
                  onTap: () {
                    // Navigate and pass event details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsPage(
                          eventId: doc.id, // Pass the Firestore document ID
                          eventData: data, // Pass the event data map
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      // Use curiousBlue.shade900 for the accent gradient
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.04), // Dark blue hint
                          accentColor
                              .withOpacity(0.01), // Lighter dark blue hint
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    // Use the dark accent color for titles
                                    color: accentColor,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Ensure icons use primary color for consistency
                            Icon(Icons.calendar_today,
                                size: 16, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(formattedDate),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Ensure icons use primary color for consistency
                            Icon(Icons.location_on,
                                size: 16, color: scheme.primary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(location)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: topics
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  // Use the dark accent color for chip background
                                  backgroundColor: accentColor,
                                  // Set chip text to white for contrast
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // FAB at bottom right — only for mentors
      floatingActionButton: (userRole == "mentor")
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/create-event');
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Event"),
              // Set FAB color explicitly to the dark accent color
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
