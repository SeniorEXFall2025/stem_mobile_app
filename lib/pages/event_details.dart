import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stem_mobile_app/custom_colors.dart';

// ============================================================
// EVENT DETAILS PAGE
// ============================================================
// This page displays comprehensive information about a single event
// when a user taps on an event card from the events list.
// ============================================================

class EventDetailsPage extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color accentColor = curiousBlue.shade900;

    // Adaptive color for AppBar text/icons (white in dark mode, dark blue in light mode)
    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : accentColor;

    // Adaptive background color for the AppBar (deep blue in dark mode, white in light mode)
    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;


    // ============================================================
    // DATA EXTRACTION SECTION
    // ============================================================
    final title = eventData["title"] ?? "Untitled Event";
    final description = eventData["description"] ?? "No description available";
    final dateStr = eventData["date"]; // Can be null
    final location = eventData["city"] ?? "No location specified";
    final topics = List<String>.from(eventData["topics"] ?? []);
    final organizer = eventData["organizer"] ?? "Unknown";
    final capacity = eventData["capacity"]; // Can be null
    final requirements = eventData["requirements"] ?? "None";

    // ============================================================
    // DATE FORMATTING SECTION
    // ============================================================
    String formattedDate = dateStr ?? "TBD";
    String formattedTime = "";
    if (dateStr != null) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        formattedDate =
            DateFormat.yMMMEd().format(parsedDate); // "Fri, Nov 15, 2025"
        formattedTime = DateFormat.jm().format(parsedDate); // "3:30 PM"
      } catch (_) {
        // If date parsing fails, keep the default "TBD"
      }
    }

    return Scaffold(
      // ============================================================
      // APP BAR - Use adaptive colors
      // ============================================================
      appBar: AppBar(
        title: const Text("Event Details"),
        // 3. APPLY ADAPTIVE COLORS
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share Event",
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: "Favorite Event",
            onPressed: () {
              // Implement favorite functionality
            },
          ),
        ],
      ),

      // ============================================================
      // BODY - SCROLLABLE CONTENT
      // ============================================================
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // HERO IMAGE SECTION - Use accent color gradient
            // ============================================================
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    // 4. USE ACCENT COLOR IN GRADIENT
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

            // ============================================================
            // MAIN CONTENT SECTION
            // ============================================================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // EVENT TITLE - Use accent color
                  // ============================================================
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      // 5. APPLY ACCENT COLOR TO TITLE
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // EVENT METADATA (Date, Time, Location, etc.)
                  // ============================================================
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: "Date",
                    value: formattedDate,
                    accentColor: accentColor,
                  ),

                  // Only show time if it exists
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
                    accentColor: accentColor, // Pass accent color
                  ),

                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person,
                    label: "Organizer",
                    value: organizer,
                    accentColor: accentColor, // Pass accent color
                  ),

                  // Only show capacity if it exists
                  if (capacity != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people,
                      label: "Capacity",
                      value: capacity.toString(),
                      accentColor: accentColor, // Pass accent color
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(), // Visual separator line
                  const SizedBox(height: 16),

                  // ============================================================
                  // EVENT DESCRIPTION SECTION
                  // ============================================================
                  Text(
                    "About This Event",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  // ============================================================
                  // TOPICS SECTION - Use accent color for chips
                  // ============================================================
                  if (topics.isNotEmpty) ...[
                    Text(
                      "Topics Covered",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, // Space between chips horizontally
                      runSpacing: 8, // Space between rows of chips
                      children: topics
                          .map((topic) => Chip(
                        label: Text(topic),
                        // 6. APPLY ACCENT COLOR TO CHIP
                        backgroundColor: accentColor,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ============================================================
                  // REGISTER BUTTON - Use accent color
                  // ============================================================
                  SizedBox(
                    width: double.infinity, // Make button full width
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement registration logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Registration feature coming soon!"),
                          ),
                        );
                      },
                      label: const Text("Register for Event"),
                      style: ElevatedButton.styleFrom(
                        // 7. APPLY ACCENT COLOR TO BUTTON
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

// ============================================================
// CUSTOM INFO ROW WIDGET
// ============================================================
// Updated to accept and use the accentColor for icons
// ============================================================
class _InfoRow extends StatelessWidget {
  final IconData icon; // The icon to display (e.g., Icons.calendar_today)
  final String label; // The field name (e.g., "Date")
  final String value; // The actual data (e.g., "Nov 15, 2025")
  final Color accentColor; // The color passed from the parent widget

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor, // Require the accent color
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
      children: [
        // Icon on the left
        // 8. USE ACCENT COLOR FOR ICON
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 12),

        // Label and value on the right
        Expanded(
          // Takes up remaining space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small gray label text
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              // Larger bold value text
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600, // Make value slightly bolder for contrast
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}