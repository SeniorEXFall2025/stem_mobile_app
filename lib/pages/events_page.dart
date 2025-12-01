import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'event_details.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.radiusMi});

  //radius in miles (from app_shell)
  final ValueListenable<double> radiusMi;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String? userRole;
  bool _loadingRole = true;

  //location
  Position? _currentPos;

  //radius mirror
  double _radiusMi = 10.0;

  @override
  void initState() {
    super.initState();
    _radiusMi = widget.radiusMi.value;
    widget.radiusMi.addListener(_onRadiusChanged);

    _loadUserRole();
    _initLocation();
  }

  @override
  void didUpdateWidget(covariant EventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusMi != widget.radiusMi) {
      oldWidget.radiusMi.removeListener(_onRadiusChanged);
      _radiusMi = widget.radiusMi.value;
      widget.radiusMi.addListener(_onRadiusChanged);
      setState(() {}); //rebuild to apply new radius
    }
  }

  @override
  void dispose() {
    widget.radiusMi.removeListener(_onRadiusChanged);
    super.dispose();
  }

  void _onRadiusChanged() {
    setState(() {
      _radiusMi = widget.radiusMi.value;
    });
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPos = pos);
    }
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snap =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final role = snap.data()?["role"];
      setState(() {
        userRole = role?.toString().toLowerCase();
        _loadingRole = false;
      });
    } else {
      setState(() => _loadingRole = false);
    }
  }

  double? _distanceMiTo(Map<String, dynamic> data) {
    final pos = _currentPos;
    if (pos == null) return null;
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final meters =
        Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
    return meters / 1609.344; //meters -> miles
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

    //adaptive color AppBar text/icons
    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    //adaptive background color AppBar
    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;

    final Color accentColor = curiousBlue.shade900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("STEM Events"),
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

          final docs = snapshot.data?.docs ?? [];

          //filter by distance if there's a location
          final filtered = <QueryDocumentSnapshot>[];
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final dist = _distanceMiTo(data);
            if (dist != null && dist <= _radiusMi) {
              filtered.add(d);
            }
          }

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _currentPos == null
                      ? "Location permission is required to filter events by distance."
                      : "No events within ${_radiusMi.toStringAsFixed(1)} mi.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
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

              final distMi = _distanceMiTo(data);
              final distanceLabel =
                  distMi != null ? ' • ${distMi.toStringAsFixed(1)} mi' : '';

              final cardBackgroundColor = theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: cardBackgroundColor,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsPage(
                          eventId: doc.id, //pass the Firestore document ID
                          eventData: data, //pass the event data map
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(formattedDate + distanceLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
                                  backgroundColor: accentColor,
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

      //button bottom right that's only for mentors
      floatingActionButton: (userRole == "mentor")
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
