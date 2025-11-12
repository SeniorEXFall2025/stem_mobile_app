import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:stem_mobile_app/custom_colors.dart'; // REQUIRED for curiousBlue

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
      final snap = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final role = snap.data()?["role"];
      print("🔥 Loaded user role: $role"); // debug log
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;

    final Color accentColor = curiousBlue.shade900;


    if (_loadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("STEM Events"),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: "Seed Sample Events",
            onPressed: () {
              Navigator.pushNamed(context, '/seed');
            },
          ),
        ],
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
                "🚀 No events available yet.\nGo to the SeederPage to add some!",
                textAlign: TextAlign.center,
              ),
            );
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data() as Map<String, dynamic>;

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


              final cardBackgroundColor = theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: cardBackgroundColor,
                child: Container(
                  decoration: BoxDecoration(

                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.04),
                        accentColor.withOpacity(0.01),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(formattedDate),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: scheme.primary),
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
                            .map((t) => Chip(
                          label: Text(t),
                          backgroundColor: accentColor,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ✅ FAB at bottom right — only for mentors/educators
      floatingActionButton: (userRole == "mentor" || userRole == "educator")
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-event');
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Event"),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      )
          : null,
    );
  }
}