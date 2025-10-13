import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Welcome"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: Padding( // Add padding for the content container
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 60, color: scheme.primary),
              const SizedBox(height: 15),
              Text(
                "Welcome, ${user.email ?? 'User'}",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text(
                "UID: ${user.uid}",
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),

              // 🎯 CHANGE: Wrap the buttons in a Row to make them side-by-side
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 🚀 Button 1: View STEM Events (Matching AuthPage's Signup/Secondary style)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0), // Spacing between buttons
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.event),
                        label: const Text("View Events"), // Shortened label
                        onPressed: () {
                          Navigator.pushNamed(context, '/events');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          // 🎯 Matching AuthPage Signup button: secondary background
                          backgroundColor: scheme.secondary,
                          foregroundColor: scheme.onSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 🚀 Button 2: Logout (Matching AuthPage's Login/Primary style)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0), // Spacing between buttons
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/auth', (route) => false);
                          }
                        },
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          // 🎯 Matching AuthPage Login button: primary background
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}