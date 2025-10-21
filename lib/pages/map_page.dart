import 'package:flutter/material.dart';

/// This page will eventually display a Google Map showing nearby STEM events.
/// For now, it's just a placeholder so we can test navigation and routing.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: const Center(
        child: Text(
          'Map view coming soon! 🗺️\nThis page will show event locations.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}