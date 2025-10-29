import 'package:flutter/material.dart';

/// Displays two lists of events:
/// - "Saved" → Events the user bookmarked
/// - "Registered" → Events the user signed up for
/// Uses TabBar + TabBarView to switch between them.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs total
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          // The TabBar automatically appears below the AppBar title
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Saved'),
              Tab(text: 'Registered'),
            ],
          ),
        ),
        // Each tab below corresponds to one of the tabs above
        body: const TabBarView(children: [_SavedTab(), _RegisteredTab()]),
      ),
    );
  }
}

/// Temporary widget for the "Saved" tab.
/// Later, this will display the user's bookmarked events.
class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.bookmark),
          title: Text('Saved Event (Placeholder)'),
          subtitle: Text('Bookmarked events will appear here later.'),
        ),
      ],
    );
  }
}

/// Temporary widget for the "Registered" tab.
/// Later, this will show events the user has registered for.
class _RegisteredTab extends StatelessWidget {
  const _RegisteredTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.event_available),
          title: Text('Registered Event (Placeholder)'),
          subtitle: Text('Your registered events will appear here later.'),
        ),
      ],
    );
  }
}
