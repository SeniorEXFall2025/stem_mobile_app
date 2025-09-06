import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedEventsPage extends StatelessWidget {
  const SeedEventsPage({super.key});

  Future<void> _seedEvents(BuildContext context) async {
    final events = [
      {
        "title": "AI Bootcamp",
        "description": "Intro to AI and machine learning for beginners.",
        "date": "2025-09-15",
        "location": "Denver Public Library",
        "city": "Denver",
        "topics": ["AI", "Coding"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Robotics Workshop",
        "description": "Hands-on robotics workshop for middle school students.",
        "date": "2025-09-18",
        "location": "STEM Center",
        "city": "Aurora",
        "topics": ["Robotics", "Engineering"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Space Exploration Talk",
        "description": "NASA engineer shares insights on Mars missions.",
        "date": "2025-09-20",
        "location": "Science Museum",
        "city": "Boulder",
        "topics": ["Space", "Science"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Math Hackathon",
        "description": "Solve challenging math problems in teams.",
        "date": "2025-09-22",
        "location": "MSU Denver",
        "city": "Denver",
        "topics": ["Math", "Problem Solving"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Biotech Fair",
        "description": "Explore biotechnology innovations and careers.",
        "date": "2025-09-25",
        "location": "Innovation Hub",
        "city": "Fort Collins",
        "topics": ["Biology", "Tech"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Chemistry Lab Tour",
        "description": "See live experiments with chemistry professors.",
        "date": "2025-09-27",
        "location": "CU Boulder Lab",
        "city": "Boulder",
        "topics": ["Chemistry"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Women in STEM Panel",
        "description": "Leaders in STEM fields share their experiences.",
        "date": "2025-09-28",
        "location": "Tech Hub",
        "city": "Denver",
        "topics": ["Diversity", "Leadership"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Coding for Kids",
        "description": "Fun introduction to programming for elementary students.",
        "date": "2025-10-01",
        "location": "Youth Center",
        "city": "Lakewood",
        "topics": ["Coding", "Education"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Green Energy Expo",
        "description": "Learn about solar, wind, and sustainable energy.",
        "date": "2025-10-03",
        "location": "Convention Center",
        "city": "Denver",
        "topics": ["Energy", "Environment"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Cybersecurity Basics",
        "description": "Protect yourself online with cybersecurity experts.",
        "date": "2025-10-05",
        "location": "STEM Hub",
        "city": "Aurora",
        "topics": ["Cybersecurity", "Tech"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "3D Printing Workshop",
        "description": "Design and print your first 3D model.",
        "date": "2025-10-08",
        "location": "Makerspace",
        "city": "Denver",
        "topics": ["3D Printing", "Engineering"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Astronomy Night",
        "description": "Stargazing and telescope demos for students.",
        "date": "2025-10-10",
        "location": "Observatory Park",
        "city": "Littleton",
        "topics": ["Astronomy", "Space"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "STEM Career Fair",
        "description": "Meet recruiters from leading STEM companies.",
        "date": "2025-10-12",
        "location": "Career Center",
        "city": "Denver",
        "topics": ["Careers", "Networking"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Environmental Science Workshop",
        "description": "Hands-on activities to learn about ecosystems.",
        "date": "2025-10-15",
        "location": "Nature Center",
        "city": "Golden",
        "topics": ["Environment", "Science"],
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "title": "Engineering Design Challenge",
        "description": "Teams compete to build the strongest bridge.",
        "date": "2025-10-18",
        "location": "Tech Innovation Lab",
        "city": "Denver",
        "topics": ["Engineering", "Design"],
        "createdAt": FieldValue.serverTimestamp(),
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    final ref = FirebaseFirestore.instance.collection("events");
    for (var e in events) {
      batch.set(ref.doc(), e);
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 15 STEM events seeded!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seed STEM Events"),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _seedEvents(context),
          icon: const Icon(Icons.science),
          label: const Text("Generate 15 Sample Events"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: scheme.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
