import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_mobile_app/custom_colors.dart';

// main pages that live under the bottom nav
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

  // app title shown in the top bar
  String get _appTitle => 'CO STEM Ecosystem';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'unknown';

    // scaffold background comes from the active theme (dark or light)
    final Color appBackground = theme.scaffoldBackgroundColor;

    // color for icons/text in the app bar
    final Color appBarForegroundColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    // slightly softer color for the "signed in as" subtitle
    final Color secondaryTextColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.7)
        : curiousBlue.shade900;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appBackground,
        foregroundColor: appBarForegroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // app name (same on every tab)
            Text(
              _appTitle,
              style: TextStyle(color: appBarForegroundColor),
            ),
            // signed in banner
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
            icon: Icon(Icons.menu, color: appBarForegroundColor),
            onSelected: (value) async {
              switch (value) {
                case 'about':
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/about');
                  break;
                case 'logout':
                  // close any keyboards/overlays
                  FocusScope.of(context).unfocus();

                  // sign out, then clear the stack to the auth screen
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/auth', (route) => false);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'about',
                child: Text('About'),
              ),
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
