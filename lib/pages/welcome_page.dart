import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 60, color: Colors.teal),
            const SizedBox(height: 15),
            Text(
              "Welcome, ${user.email ?? 'User'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("UID: ${user.uid}", textAlign: TextAlign.center),
            const SizedBox(height: 30),

            // 🚀 New button for events
            ElevatedButton.icon(
              icon: const Icon(Icons.event),
              label: const Text("View STEM Events"),
              onPressed: () {
                Navigator.pushNamed(context, '/events');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: scheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: scheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
