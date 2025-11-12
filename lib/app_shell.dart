import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_mobile_app/custom_colors.dart'; // REQUIRED for curiousBlue.shade900

// Main pages that live under the bottom nav
import 'pages/events_page.dart';
import 'pages/map_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    EventsPage(),
    MapPage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  String get _title {
    switch (_index) {
      case 0:
        return 'Home';
      case 1:
        return 'Map';
      case 2:
        return 'Favorites';
      case 3:
        return 'Settings';
      default:
        return 'STEM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'unknown';

    // The scaffold background is set by the overall theme (dark975 in dark mode)
    final Color appBackground = theme.scaffoldBackgroundColor;

    // Determines the color for text/icons on the AppBar
    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    // Determines the secondary text color for the user's email
    final Color secondaryTextColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.7) // Light text on dark background
        : Colors.black54; // Dark text on light background

    return Scaffold(
      backgroundColor: appBackground, // Match the AuthPage's deep blue background
      appBar: AppBar(
        // Match the background color to the deep blue scaffold background
        backgroundColor: appBackground,
        // Set the color for the icons (PopupMenuButton)
        foregroundColor: appBarForegroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title text color
            Text(_title, style: TextStyle(color: appBarForegroundColor)),
            // Subtitle text color
            Text(
              'Signed in as $userEmail',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: appBarForegroundColor), // Ensure menu icon is adaptive
            onSelected: (value) async {
              switch (value) {
                case 'create':
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/create-event');
                  break;
                case 'interests':
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/onboarding');
                  break;
                case 'about':
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/about');
                  break;
                case 'logout':
                // Close any keyboards/overlays
                  FocusScope.of(context).unfocus();

                  // Sign out, then clear the stack to the Auth screen.
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/auth', (route) => false);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'create', child: Text('Create Event')),
              const PopupMenuItem(
                value: 'interests',
                child: Text('Edit Interests'),
              ),
              const PopupMenuItem(value: 'about', child: Text('About')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout ($userEmail)'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              // CHANGE: Use the dark, bold blue (curiousBlue.shade900)
              // to match the primary buttons on the AuthPage
              color: curiousBlue.shade900,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Colors.black26,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavIcon(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavIcon(
                  icon: Icons.star_rounded,
                  label: 'Favorites',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavIcon(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}