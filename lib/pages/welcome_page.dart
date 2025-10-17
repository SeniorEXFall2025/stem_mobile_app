import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The first screen shown after login or onboarding.
/// Displays the user's email + UID and offers navigation options.
/// NOTE: This page temporarily includes navigation test buttons
/// for new routes (Map, Favorites, Event Detail) until we add a nav bar.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current signed-in Firebase user
    final user = FirebaseAuth.instance.currentUser!;

    // Theme references for consistent colors
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // 🔹 AppBar
      appBar: AppBar(
        title: const Text("Welcome"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        elevation: 0, // removes drop shadow for a flat design
      ),

      // 🔹 Main body content
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Welcome icon + user info
              Icon(Icons.verified_user, size: 60, color: scheme.primary),
              const SizedBox(height: 15),
              Text(
                "Welcome, ${user.email ?? 'User'}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "UID: ${user.uid}",
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),

              // 🔹 Primary buttons row: View Events + Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 🚀 Button 1: View STEM Events
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.event),
                        label: const Text("View Events"),
                        onPressed: () {
                          Navigator.pushNamed(context, '/events');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: scheme.secondary,
                          foregroundColor: scheme.onSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 🚀 Button 2: Logout
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/auth',
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 🌟 TEMPORARY TEST BUTTONS 🌟
              // These are just for testing that new routes (Map, Favorites, Event Detail) work.
              // We can remove them once the navigation bar is implemented.
              const Divider(height: 40, thickness: 1),
              const Text(
                "🔧 Temporary Buttons for Testing Navigation",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Wrap in a column for vertical layout
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Go to Map Page"),
                    onPressed: () {
                      Navigator.pushNamed(context, '/map');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.favorite),
                    label: const Text("Go to Favorites Page"),
                    onPressed: () {
                      Navigator.pushNamed(context, '/favorites');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info),
                    label: const Text("Go to Event Detail Page"),
                    onPressed: () {
                      Navigator.pushNamed(context, '/event');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                ],
              ),
              // 🧹 End of temporary testing section
            ],
          ),
        ),
      ),
    );
  }
}
