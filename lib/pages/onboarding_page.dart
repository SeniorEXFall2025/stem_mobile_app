import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../custom_colors.dart' as app_colors;
import '../app_shell.dart';

final List<String> _roles = const ['Student', 'Mentor/Educator'];
final Map<String, String> _roleMap = const {
  'Student': 'student',
  'Mentor/Educator': 'mentor',
};
final List<String> _interests = const [
  'AI',
  'Robotics',
  'Math',
  'Biology',
  'Space',
  'Coding',
];

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
  bool _roleLocked = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  // --- ORIGINAL FIREBASE LOGIC PRESERVED ---
  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!snap.exists) return;
      final data = snap.data();
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
          _roleLocked = true;
        }
        if (storedInterests is List) {
          _selectedInterests.addAll(
            storedInterests
                .whereType<String>()
                .where((i) => _interests.contains(i)),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'We’re not signed in. Try logging in again.');
      return;
    }
    if (_selectedRole == null || _selectedInterests.isEmpty) {
      setState(() => _error = 'Pick a role and at least one interest.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final roleValue = _roleMap[_selectedRole] ?? _selectedRole;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': roleValue,
        'interests': _selectedInterests.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.waitForPendingWrites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved for ${user.email ?? 'this account'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

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

  // --- BUILD METHOD FINALIZED ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // FIX: Use the darker shade (shade900) to match the Login button color.
    final Color primaryButtonColor = app_colors.curiousBlue.shade900;
    // The text/icon color that contrasts with the dark button color is white.
    const Color onPrimaryButtonColor = Colors.white;

    final Color bodyTextColor = scheme.onBackground;

    // Unselected chip background is dark in dark mode, light in light mode
    final Color unselectedChipColor = theme.brightness == Brightness.dark
        ? app_colors.dark900
        : scheme.surface;

    return Scaffold(
      // THEME-AWARE: Scaffold Background
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        // Consistent dark header color
        backgroundColor: app_colors.curiousBlue.shade900,

        // Ensure text and icons are white on the dark blue
        title: const Text(
          'Set up our profile',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        elevation: 8.0,

        // STYLE: Rounded Corner
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),

      body: SafeArea(
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
                  color: bodyTextColor,
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

                    // BUTTON COLOR: Use dark shade for selected
                    selectedColor: primaryButtonColor,
                    backgroundColor: unselectedChipColor,

                    labelStyle: TextStyle(
                      // Text color contrasts with dark button color (white)
                      color: selected ? onPrimaryButtonColor : bodyTextColor,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? primaryButtonColor : scheme.outline,
                    ),

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
                    color: bodyTextColor.withOpacity(0.7),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // --- Interests selection ---
              Text(
                'Pick our interests:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: bodyTextColor,
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

                    // BUTTON COLOR: Use dark shade for selected
                    selectedColor: primaryButtonColor,
                    backgroundColor: unselectedChipColor,

                    labelStyle: TextStyle(
                      color: selected ? onPrimaryButtonColor : bodyTextColor,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? primaryButtonColor : scheme.outline,
                    ),

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
                    ? CircularProgressIndicator(color: primaryButtonColor)
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: onPrimaryButtonColor),
                  label: const Text(
                    'Save',
                    style: TextStyle(color: onPrimaryButtonColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: (_selectedRole != null &&
                      _selectedInterests.isNotEmpty)
                      ? _saveProfile
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    // BUTTON COLOR: Use dark shade for background
                    backgroundColor: primaryButtonColor,
                    foregroundColor: onPrimaryButtonColor,
                    disabledBackgroundColor: primaryButtonColor.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}