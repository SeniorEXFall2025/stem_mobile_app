import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_shell.dart';

/// Onboarding collects two things:
/// 1) our role (Student or Mentor/Educator)
/// 2) a few interests to shape the feed
///
/// After we save, we optimistically jump into the app (AppShell),
/// and let the profile stream in main.dart keep us synced.
///
/// When this page is opened from Settings later, we let the user
/// change their interests but keep the original role locked.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String? _selectedRole;
  final Set<String> _selectedInterests = {};
  bool _saving = false;
  String _error = '';

  // Once a role is set, we keep it locked when editing interests later.
  bool _roleLocked = false;

  // Display roles shown as chips.
  final List<String> _roles = const ['Student', 'Mentor/Educator'];

  // Map from display label -> stored code in Firestore.
  final Map<String, String> _roleMap = const {
    'Student': 'student',
    'Mentor/Educator': 'mentor',
  };

  // Starter list — we can expand this anytime.
  final List<String> _interests = const [
    'AI',
    'Robotics',
    'Math',
    'Biology',
    'Space',
    'Coding',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  /// Load any existing profile so:
  /// - first-time users see empty role + interests
  /// - returning users see their current role (locked) and interests selected
  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) return;

      final data = snap.data(); // already Map<String, dynamic>?

      if (data == null) return;

      final storedRole = data['role'];
      final storedInterests = data['interests'];

      String? displayRole;

      if (storedRole is String) {
        switch (storedRole) {
          case 'student':
            displayRole = 'Student';
            break;
          case 'mentor':
          case 'educator':
            displayRole = 'Mentor/Educator';
            break;
        }
      }

      setState(() {
        if (displayRole != null) {
          _selectedRole = displayRole;
          _roleLocked = true; // role already set, keep it locked
        }

        if (storedInterests is List) {
          // Only keep interests that are in our current list and are strings
          _selectedInterests.addAll(
            storedInterests
                .whereType<String>()
                .where((i) => _interests.contains(i)),
          );
        }
      });
    } catch (_) {
      // If this fails, onboarding still works; the user can just fill it out.
    }
  }

  /// Save role + interests. For first-time users this sets both.
  /// For users editing via Settings, roleLocked prevents role from changing,
  /// so this mainly updates interests.
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    // If we somehow got here without an auth user, surface it.
    if (user == null) {
      setState(() => _error = 'We’re not signed in. Try logging in again.');
      return;
    }

    // Basic validation.
    if (_selectedRole == null || _selectedInterests.isEmpty) {
      setState(() => _error = 'Pick a role and at least one interest.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      // Translate display label back to the stored code.
      final roleValue = _roleMap[_selectedRole] ?? _selectedRole;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': roleValue,
        'interests': _selectedInterests.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email, // handy for debugging in the console
      }, SetOptions(merge: true));

      // Make sure any local pending writes are flushed before we navigate.
      await FirebaseFirestore.instance.waitForPendingWrites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved for ${user.email ?? 'this account'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Jump straight into the app shell.
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Couldn’t save profile: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up our profile'),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // Soft background gradient that follows the theme.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withOpacity(0.05),
              scheme.secondary.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Role selection ---
                Text(
                  'Select our role:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _roles.map((role) {
                    final selected = _selectedRole == role;
                    return ChoiceChip(
                      label: Text(role),
                      selected: selected,
                      selectedColor: scheme.secondary.withOpacity(0.30),
                      // If role is locked, disable tap handling
                      onSelected: _roleLocked
                          ? null
                          : (_) => setState(() => _selectedRole = role),
                    );
                  }).toList(),
                ),
                if (_roleLocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Role is set for this account. Use Edit interests to update topics.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // --- Interests selection ---
                Text(
                  'Pick our interests:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _interests.map((topic) {
                    final selected = _selectedInterests.contains(topic);
                    return FilterChip(
                      label: Text(topic),
                      selected: selected,
                      selectedColor: scheme.primaryContainer.withOpacity(0.35),
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? _selectedInterests.remove(topic)
                              : _selectedInterests.add(topic);
                        });
                      },
                    );
                  }).toList(),
                ),

                const Spacer(),

                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error, style: TextStyle(color: scheme.error)),
                  ),

                // --- Save button ---
                Center(
                  child: _saving
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Save'),
                          onPressed: (_selectedRole != null &&
                                  _selectedInterests.isNotEmpty)
                              ? _saveProfile
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
