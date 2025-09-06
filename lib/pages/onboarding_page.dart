import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String? selectedRole;
  final Set<String> selectedInterests = {};

  final roles = ["Student", "Mentor", "Educator"];
  final interests = ["AI", "Robotics", "Math", "Biology", "Space", "Coding"];

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "role": selectedRole,
      "interests": selectedInterests.toList(),
    });

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup Your Profile"),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary.withOpacity(0.05), scheme.secondary.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select your role:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      )),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: roles.map((r) {
                  return ChoiceChip(
                    label: Text(r),
                    selected: selectedRole == r,
                    selectedColor: scheme.secondary.withOpacity(0.3),
                    onSelected: (_) => setState(() => selectedRole = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Text("Pick your interests:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.secondary,
                      )),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: interests.map((i) {
                  final selected = selectedInterests.contains(i);
                  return FilterChip(
                    label: Text(i),
                    selected: selected,
                    selectedColor: scheme.tertiary.withOpacity(0.3),
                    onSelected: (_) {
                      setState(() {
                        selected
                            ? selectedInterests.remove(i)
                            : selectedInterests.add(i);
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Save"),
                  onPressed: selectedRole != null && selectedInterests.isNotEmpty
                      ? _saveProfile
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    backgroundColor: scheme.primary,
                    foregroundColor: Colors.white,
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
