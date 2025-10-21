import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String selectedOption = 'All Events';

  // Example list of events
  List<String> allEvents = [
    'Event A',
    'Event B',
    'Event C',
    'Event D',
  ];

  List<String> favoriteEvents = [
    'Event A',
    'Event C',
  ];

  List<String> displayedEvents = [];

  @override
  void initState() {
    super.initState();
    // Show all events by default
    displayedEvents = List.from(allEvents);
  }

  void _updateContent(String option) {
    setState(() {
      selectedOption = option;
      if (option == 'Search Events' || option == 'All Events') {
        displayedEvents = List.from(allEvents);
      } else if (option == 'Favorites') {
        displayedEvents = List.from(favoriteEvents);
      } else if (option == 'Create Event') {
        displayedEvents = []; // You can show a form here later
      }
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(selectedOption)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Navigation',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              title: const Text('All Events'),
              onTap: () => _updateContent('All Events'),
            ),
            ListTile(
              title: const Text('Search Events'),
              onTap: () => _updateContent('Search Events'),
            ),
            ListTile(
              title: const Text('Favorites'),
              onTap: () => _updateContent('Favorites'),
            ),
            ListTile(
              title: const Text('Create Event'),
              onTap: () => _updateContent('Create Event'),
            ),
          ],
        ),
      ),
      body: displayedEvents.isEmpty
          ? Center(
              child: selectedOption == 'Create Event'
                  ? const Text('Create a new event here!')
                  : const Text('No events to display'),
            )
          : ListView.builder(
              itemCount: displayedEvents.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(displayedEvents[index]),
                  leading: const Icon(Icons.event),
                );
              },
            ),
    );
  }
}


