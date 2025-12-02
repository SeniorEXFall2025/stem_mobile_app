import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_mobile_app/custom_colors.dart';

// main pages that live under the bottom nav
import 'pages/events_page.dart';
import 'pages/map_page.dart';
import 'pages/favorites_page.dart';
import 'pages/organizations_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // proximity radius in miles (shared to pages)
  final ValueNotifier<double> _radiusMi = ValueNotifier<double>(10.0);

  late List<Widget> _pages;

  String get _appTitle => 'CO STEM Ecosystem';

  @override
  void initState() {
    super.initState();
    _pages = [
      EventsPage(radiusMi: _radiusMi),   // 0 - Home
      MapPage(radiusMi: _radiusMi),      // 1 - Map
      const FavoritesPage(),             // 2 - Favorites
      const OrganizationsPage(),         // 3 - Orgs
    ];
  }

  @override
  void dispose() {
    _radiusMi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'unknown';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 8,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                curiousBlue.shade800,
                curiousBlue.shade900,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // circular logo
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/co_stem_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover, // crop into the circle
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Signed in as $userEmail',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _RadiusMenu(
            appBarForegroundColor: Colors.white,
            radiusMi: _radiusMi,
            userEmail: userEmail,
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
                  icon: Icons.apartment_rounded,
                  label: 'Orgs',
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

class _RadiusMenu extends StatefulWidget {
  final Color appBarForegroundColor;
  final ValueNotifier<double> radiusMi;
  final String userEmail;

  const _RadiusMenu({
    required this.appBarForegroundColor,
    required this.radiusMi,
    required this.userEmail,
  });

  @override
  State<_RadiusMenu> createState() => _RadiusMenuState();
}

class _RadiusMenuState extends State<_RadiusMenu> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return MenuAnchor(
      controller: _menuController,
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Menu',
          icon: Icon(Icons.menu, color: widget.appBarForegroundColor),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Search radius',
            style: theme.textTheme.labelLarge?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ValueListenableBuilder<double>(
          valueListenable: widget.radiusMi,
          builder: (context, value, _) {
            final clamped = value.clamp(0.5, 50.0);
            return SizedBox(
              width: 280,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 0.5,
                        max: 50,
                        divisions: 99,
                        value: clamped,
                        activeColor: curiousBlue.shade700,
                        label: '${clamped.toStringAsFixed(1)} mi',
                        onChanged: (v) => widget.radiusMi.value = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: curiousBlue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: curiousBlue.shade300,
                        ),
                      ),
                      child: Text(
                        '${clamped.toStringAsFixed(1)} mi',
                        style: TextStyle(
                          color: curiousBlue.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 8),

        MenuItemButton(
          onPressed: () {
            _menuController.close();
            Navigator.pushNamed(context, '/settings');
          },
          child: Text(
            'Settings',
            style: TextStyle(color: onSurface),
          ),
        ),
        MenuItemButton(
          onPressed: () {
            _menuController.close();
            Navigator.pushNamed(context, '/about');
          },
          child: Text(
            'About',
            style: TextStyle(color: onSurface),
          ),
        ),
        MenuItemButton(
          onPressed: () async {
            _menuController.close();
            FocusScope.of(context).unfocus();
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/auth',
              (route) => false,
            );
          },
          child: Text(
            'Logout (${widget.userEmail})',
            style: TextStyle(color: onSurface),
          ),
        ),
      ],
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
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
