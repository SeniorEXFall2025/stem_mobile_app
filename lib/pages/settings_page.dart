import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_mobile_app/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.brightness == Brightness.dark ? Colors.white : scheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic account info card
              Card(
                elevation: 2,
                child: ListTile(
                  title: const Text('Account'),
                  subtitle: Text(user?.email ?? 'No email'),
                  leading: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Pull role + interests from Firestore so this screen can show our profile
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: (user == null)
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    String roleLabel = 'Not set yet';
                    List<dynamic> interests = const [];

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        final role = data['role'];
                        final list = data['interests'];
                        if (role is String && role.isNotEmpty) {
                          roleLabel = role;
                        }
                        if (list is List) {
                          interests = list;
                        }
                      }
                    }

                    return ListView(
                      children: [
                        // Role summary
                        Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.badge),
                            title: const Text('Role'),
                            subtitle: Text(roleLabel),
                          ),
                        ),

                        // Interests summary (only if we actually have some)
                        if (interests.isNotEmpty)
                          Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.interests),
                              title: const Text('Interests'),
                              subtitle: Text(interests.join(', ')),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Edit interests reuses the onboarding flow
                        Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Edit interests'),
                            subtitle: const Text(
                              'Update topics we care about for the feed',
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/onboarding');
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Theme section – flips the app theme.
                        Card(
                          elevation: 2,
                          child: ValueListenableBuilder<ThemeMode>(
                            valueListenable: ThemeController.themeMode,
                            builder: (context, mode, _) {
                              final isDark = mode == ThemeMode.dark;

                              return ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: const Text('Dark mode'),
                                subtitle: const Text(
                                  'Toggle between light and dark theme for the app.',
                                ),
                                trailing: Switch(
                                  value: isDark,
                                  activeThumbColor: scheme.primary,
                                  onChanged: (value) {
                                    ThemeController.setThemeMode(
                                      value
                                          ? ThemeMode.dark
                                          : ThemeMode.light,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
