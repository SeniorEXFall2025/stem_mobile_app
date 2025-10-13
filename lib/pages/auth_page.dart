import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = "";

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create Firestore profile with empty role & interests
      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "role": null,
        "interests": [],
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _status = "🔥 Signup error: ${e.message}");
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .get();

      final data = doc.data() ?? {};
      final role = data["role"];
      final interests = (data["interests"] ?? []) as List;

      if (mounted) {
        if (role == null || interests.isEmpty) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _status = "🔥 Login error: ${e.message}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Check if we are in dark mode to apply specific background/surface colors
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // Uses the main theme's scaffoldBackgroundColor (dark blue-grey)
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Login / Signup"),
        // Use the darker background color for the AppBar to blend with the scaffold
        backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : scheme.primary,
        // Using scheme.onSurface (recommended text color on a dark surface)
        foregroundColor: isDarkMode ? scheme.onSurface : scheme.onPrimary,
        elevation: 0, // Remove shadow for a flatter look
      ),
      body: Center(
        child: Container(
          // Use a Card or Container to represent the elevated form area
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            // Use scheme.surface (blueGrey[800]) for the card background for depth
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // 🎯 FIX: Replaced deprecated withOpacity with explicit hex color (0x1A is ~10% opacity)
              if (!isDarkMode)
                const BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep the container minimal
              children: [
                // Title (using primary color for a bright splash)
                Text(
                  "Welcome Back",
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: scheme.onSurfaceVariant),
                    labelText: "Email",
                    labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    // Use the main theme's scaffold background color for the text field input area
                    fillColor: theme.scaffoldBackgroundColor,
                    filled: true,
                    // Vibrant blue focus border
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2.0),
                    ),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Enter an email" : null,
                ),
                const SizedBox(height: 15),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: scheme.onSurfaceVariant),
                    labelText: "Password",
                    labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    // Use the main theme's scaffold background color for the text field input area
                    fillColor: theme.scaffoldBackgroundColor,
                    filled: true,
                    // Vibrant blue focus border
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2.0),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Enter a password";
                    if (val.length < 6) return "Min 6 characters required";
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Signup button: secondary (light grey) and onSecondary (dark text)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.secondary,
                            foregroundColor: scheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.person_add),
                          onPressed: _signup,
                          label: const Text("Signup"),
                        ),
                      ),
                    ),

                    // Login button: primary (vibrant blue) color
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.login),
                          onPressed: _login,
                          label: const Text("Login"),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Text
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}