import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============================================================
// EVENT DETAILS PAGE
// ============================================================
// This page displays comprehensive information about a single event
// when a user taps on an event card from the events list.
//
// ALTERNATIVES YOU COULD ADD:
// - Add a photo/image field for events
// - Add a map widget showing event location
// - Add attendee list
// - Add sharing functionality (share event via social media)
// - Add "Add to Calendar" button
// - Add rating/review system
// ============================================================

class EventDetailsPage extends StatelessWidget {
  // EventDetailsPage receives data from the previous screen
  final String eventId; // Unique ID from Firestore
  final Map<String, dynamic> eventData; // All event data (title, date, etc.)

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    // Get the app's color scheme for consistent theming
    final scheme = Theme.of(context).colorScheme;

    // ============================================================
    // DATA EXTRACTION SECTION
    // ============================================================
    // Extract all fields from the eventData map with fallback values
    // The ?? operator provides default values if the field is null
    //
    // ALTERNATIVES:
    // - Add more fields like: address, contactEmail, phoneNumber
    // - Add imageUrl for event photos
    // - Add registrationDeadline
    // - Add maxAge, minAge for age restrictions
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
    // Convert the date string from Firestore into human-readable format
    // Example: "2025-11-15" becomes "Fri, Nov 15, 2025"
    //
    // ALTERNATIVES:
    // - Show "days until event" (e.g., "In 5 days")
    // - Show relative time (e.g., "Next Friday")
    // - Add countdown timer for upcoming events
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
      // APP BAR
      // ============================================================
      // Top navigation bar with back button
      //
      // ALTERNATIVES:
      // - Add share button in actions
      // - Add favorite/bookmark button
      // - Add edit button (for organizers only)
      // - Add delete button (for organizers only)
      // ============================================================
      appBar: AppBar(
        title: const Text("Event Details"),
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
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        // You could add actions here:
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.share),
        //     onPressed: () { /* Share event */ },
        //   ),
        // ],
      ),

      // ============================================================
      // BODY - SCROLLABLE CONTENT
      // ============================================================
      // SingleChildScrollView allows the content to scroll if it's too long
      // for the screen. Without this, content would be cut off.
      //
      // ALTERNATIVES:
      // - Use ListView instead for better performance with many items
      // - Add pull-to-refresh functionality
      // - Add sticky header that stays at top when scrolling
      // ============================================================
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // HERO IMAGE SECTION
            // ============================================================
            // Large banner at the top with gradient background
            // Currently shows a placeholder icon
            //
            // ALTERNATIVES:
            // - Replace with actual event photo from Firestore
            // - Add parallax scrolling effect
            // - Add overlay with event title on top of image
            // - Use NetworkImage to load image from URL:
            //   Image.network(eventData["imageUrl"])
            // - Add Hero animation from list to detail page
            // ============================================================
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.secondary,
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
            // All the event details with padding around them
            // ============================================================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // EVENT TITLE
                  // ============================================================
                  // Large, bold title at the top
                  //
                  // ALTERNATIVES:
                  // - Add subtitle/tagline
                  // - Add event status badge (e.g., "Full", "Open", "Cancelled")
                  // ============================================================
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // EVENT METADATA (Date, Time, Location, etc.)
                  // ============================================================
                  // Using custom _InfoRow widget to display key information
                  // Each row has an icon, label, and value
                  //
                  // ALTERNATIVES:
                  // - Add contact information (email, phone)
                  // - Add price/cost information
                  // - Add registration deadline
                  // - Add "spots remaining" counter
                  // - Make location clickable to open in maps
                  // ============================================================
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: "Date",
                    value: formattedDate,
                  ),

                  // Only show time if it exists
                  if (formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: "Time",
                      value: formattedTime,
                    ),
                  ],

                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: "Location",
                    value: location,
                    // ALTERNATIVE: Make this clickable
                    // onTap: () => _openInMaps(location)
                  ),

                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person,
                    label: "Organizer",
                    value: organizer,
                  ),

                  // Only show capacity if it exists
                  if (capacity != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people,
                      label: "Capacity",
                      value: capacity.toString(),
                      // ALTERNATIVE: Show as "50 / 100" with registered count
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(), // Visual separator line
                  const SizedBox(height: 16),

                  // ============================================================
                  // EVENT DESCRIPTION SECTION
                  // ============================================================
                  // Full text description of the event
                  //
                  // ALTERNATIVES:
                  // - Add "Read More" button if description is very long
                  // - Add bullet points for key highlights
                  // - Add rich text formatting (bold, italic)
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
                  // TOPICS SECTION
                  // ============================================================
                  // Display all topics as colored chips
                  // Wrap widget automatically moves chips to next line if needed
                  //
                  // ALTERNATIVES:
                  // - Make topics clickable to filter other events by topic
                  // - Add icons for each topic type
                  // - Use different colors for different topic categories
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
                                backgroundColor: scheme.secondaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                // ALTERNATIVE: Make clickable
                                // onPressed: () => _filterByTopic(topic)
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ============================================================
                  // REGISTER BUTTON
                  // ============================================================
                  // Main call-to-action button at the bottom
                  // Currently just shows a placeholder message
                  //
                  // ALTERNATIVES TO IMPLEMENT:
                  // - Save registration to Firestore:
                  //   FirebaseFirestore.instance
                  //     .collection("events").doc(eventId)
                  //     .collection("registrations").add({
                  //       "userId": FirebaseAuth.instance.currentUser!.uid,
                  //       "registeredAt": FieldValue.serverTimestamp(),
                  //     });
                  // - Check if user already registered (change button to "Unregister")
                  // - Check if event is full (disable button)
                  // - Send confirmation email
                  // - Add to user's calendar
                  // - Show dialog to collect additional info (dietary restrictions, etc.)
                  // - Replace with "Cancel Registration" if already registered
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
                        backgroundColor: scheme.primary,
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
// Reusable component that displays a labeled piece of information
// with an icon, label, and value in a consistent format
//
// WHY THIS IS USEFUL:
// - Avoids code duplication (DRY principle)
// - Maintains consistent styling across all info rows
// - Easy to modify all info rows by changing this one widget
//
// ALTERNATIVES:
// - Make it a ListTile for built-in tap handling
// - Add onTap callback to make rows interactive
// - Add copyable text (long press to copy)
// - Add different styles for different types of info
// ============================================================
class _InfoRow extends StatelessWidget {
  final IconData icon; // The icon to display (e.g., Icons.calendar_today)
  final String label; // The field name (e.g., "Date")
  final String value; // The actual data (e.g., "Nov 15, 2025")

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
      children: [
        // Icon on the left
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ADDITIONAL FEATURES YOU COULD ADD TO THIS PAGE:
// ============================================================
// 1. IMAGE GALLERY: Show multiple event photos
// 2. ATTENDEE LIST: Show who else is registered
// 3. COMMENTS/QUESTIONS: Let users ask questions
// 4. SIMILAR EVENTS: Show related events at the bottom
// 5. WEATHER FORECAST: For outdoor events
// 6. NAVIGATION: Direct link to Google Maps
// 7. SOCIAL SHARING: Share to Facebook, Twitter, etc.
// 8. QR CODE: Generate QR code for event check-in
// 9. NOTIFICATIONS: Remind me button
// 10. REVIEWS: After event, let users leave reviews
// 11. LIVESTREAM: If event is virtual/hybrid
// 12. AGENDA/SCHEDULE: Detailed timeline of activities
// 13. SPEAKERS/PRESENTERS: Bio and photos
// 14. SPONSORS: Show event sponsors with logos
// 15. FAQs: Frequently asked questions section
// ============================================================
