import 'package:flutter/material.dart';

/// Simple placeholder page for user settings or account preferences.
/// Right now this is just a stub so the nav bar has somewhere to go.
/// We will add real settings later (like notification toggles or profile info).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: Text('Settings (placeholder)', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
