import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// EVENT DETAILS PAGE
// ============================================================
// This page displays all the information for a single event.
// It also lets the user:
// - save the event to Favorites (star icon)
// - register / unregister for the event (button at the bottom)
// Both of those are stored under the current user in Firestore:
//   users/{uid}/favorites/{eventId}
//   users/{uid}/registrations/{eventId}
// ============================================================

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _isFavorite = false;
  bool _isRegistered = false;
  bool _busyFavorite = false;
  bool _busyRegister = false;

  @override
  void initState() {
    super.initState();
    _loadInitialStates();
  }

  Future<void> _loadInitialStates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final favSnap =
          await userDoc.collection('favorites').doc(widget.eventId).get();
      final regSnap =
          await userDoc.collection('registrations').doc(widget.eventId).get();

      if (!mounted) return;

      setState(() {
        _isFavorite = favSnap.exists;
        _isRegistered = regSnap.exists;
      });
    } catch (_) {
      // If this fails, we just leave the defaults (not saved / not registered).
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be signed in to save events.')),
      );
      return;
    }

    setState(() {
      _busyFavorite = true;
    });

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final favRef = userDoc.collection('favorites').doc(widget.eventId);

      if (_isFavorite) {
        await favRef.delete();
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved events.')),
        );
      } else {
        // Store the event snapshot so FavoritesPage can display it nicely
        await favRef.set({
          'eventId': widget.eventId,
          'eventData': widget.eventData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your favorites.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorites: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to register.')),
      );
      return;
    }

    setState(() {
      _busyRegister = true;
    });

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final regRef = userDoc.collection('registrations').doc(widget.eventId);

      if (_isRegistered) {
        // Let the user unregister if they tap again
        await regRef.delete();
        if (!mounted) return;
        setState(() {
          _isRegistered = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are no longer registered.')),
        );
      } else {
        await regRef.set({
          'eventId': widget.eventId,
          'eventData': widget.eventData,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          _isRegistered = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered for this event.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update registration: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyRegister = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accentColor = curiousBlue.shade900;

    // AppBar colors stay adaptive
    final Color appBarForegroundColor =
        theme.brightness == Brightness.dark ? Colors.white : accentColor;
    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;

    // Pull fields out of the event data
    final title = widget.eventData["title"] ?? "Untitled Event";
    final description =
        widget.eventData["description"] ?? "No description available";
    final dateStr = widget.eventData["date"]; // Can be null
    final location = widget.eventData["city"] ?? "No location specified";
    final topics = List<String>.from(widget.eventData["topics"] ?? []);
    final organizer = widget.eventData["organizer"] ?? "Unknown";
    final capacity = widget.eventData["capacity"]; // Can be null
    final String? requirements =
        (widget.eventData["requirements"] as String?)?.trim();

    // Format the date/time from the ISO string we store in Firestore
    String formattedDate = dateStr ?? "TBD";
    String formattedTime = "";
    if (dateStr != null) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        formattedDate = DateFormat.yMMMEd().format(parsedDate);
        formattedTime = DateFormat.jm().format(parsedDate);
      } catch (_) {
        // If parsing fails, leave it as "TBD"
      }
    }

    final String registerLabel =
        _isRegistered ? "Registered" : "Register for Event";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share Event",
            onPressed: () {
              // Someone else on the team wants to handle sharing later.
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
            ),
            tooltip:
                _isFavorite ? "Remove from saved events" : "Save to favorites",
            onPressed: _busyFavorite ? null : _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top banner with event icon
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.8),
                    accentColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.event,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Basic info rows
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: "Date",
                    value: formattedDate,
                    accentColor: accentColor,
                  ),
                  if (formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: "Time",
                      value: formattedTime,
                      accentColor: accentColor,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: "Location",
                    value: location,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person,
                    label: "Organizer",
                    value: organizer,
                    accentColor: accentColor,
                  ),
                  if (capacity != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people,
                      label: "Capacity",
                      value: capacity.toString(),
                      accentColor: accentColor,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    "About This Event",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  // Optional requirements
                  if (requirements != null && requirements.isNotEmpty) ...[
                    Text(
                      "Requirements",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requirements,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Topics
                  if (topics.isNotEmpty) ...[
                    Text(
                      "Topics Covered",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topics
                          .map(
                            (topic) => Chip(
                              label: Text(topic),
                              backgroundColor: accentColor,
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busyRegister ? null : _toggleRegistration,
                      label: Text(registerLabel),
                      icon: Icon(
                        _isRegistered ? Icons.check : Icons.launch,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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

// Simple row for icon + label + value
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
