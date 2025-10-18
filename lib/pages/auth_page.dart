import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple email/password auth screen.
/// - Login: go to '/' so main.dart decides (→ AppShell / Onboarding)
/// - Signup: create Firestore user doc, then go to /onboarding
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _status = ""; // shows error/info text under buttons
  bool _busy = false; // shows a spinner while we hit Firebase

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Create a new account, make a profile doc, then onboard
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    // Close the keyboard so taps don't double-submit.
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _status = "";
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      // Wait until this exact UID is the active user (avoids race after sign out).
      await FirebaseAuth.instance.userChanges().firstWhere(
        (u) => u != null && u.uid == cred.user!.uid, // <- no "!" after u
      );

      // Create Firestore profile with empty role & interests
      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .set({
            "role": null,
            "interests": <String>[],
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      // Visual confirmation so we know auth succeeded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed up as ${cred.user?.email ?? 'unknown'}'),
        ),
      );

      // New users should pick role/interests
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    } on FirebaseAuthException catch (e) {
      final msg = 'Signup error [${e.code}]: ${e.message}';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      final msg = 'Signup error: $e';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Log in existing user, then let main.dart decide (AppShell/Onboarding)
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _status = "";
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      // Wait for the *new* user to be fully active (prevents stuck UI when switching accounts).
      await FirebaseAuth.instance.userChanges().firstWhere(
        (u) => u != null && u.uid == cred.user!.uid, // <- no "!" after u
      );

      if (!mounted) return;

      // Clear fields so the next visit starts fresh.
      _email.clear();
      _password.clear();

      // Visual confirmation so we know auth succeeded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in as ${cred.user?.email ?? 'unknown'}'),
        ),
      );

      // Go to root so the Stream in main.dart decides where to go.
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      final msg = 'Login error [${e.code}]: ${e.message}';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      final msg = 'Login error: $e';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // Uses the app's scaffold background color (dark blue/grey in our theme)
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Login / Signup"),
        // Keep it visually flat with the scaffold
        backgroundColor: isDarkMode
            ? theme.scaffoldBackgroundColor
            : scheme.primary,
        foregroundColor: isDarkMode ? scheme.onSurface : scheme.onPrimary,
        elevation: 0,
      ),

      body: Center(
        child: Container(
          // Keep the form from stretching too wide on desktop/web
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            // Slightly elevated card look using the theme surface
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Light mode gets a soft drop shadow; dark mode stays flat
              if (!isDarkMode)
                const BoxShadow(
                  color: Color(0x1A000000), // ~10% black
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
            ],
          ),

          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep the card compact
              children: [
                // Title
                Text(
                  "Welcome Back",
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // ✉️ Email
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email,
                      color: scheme.onSurfaceVariant,
                    ),
                    labelText: "Email",
                    labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2.0),
                    ),
                  ),
                  validator: (val) {
                    final t = val?.trim() ?? '';
                    if (t.isEmpty) return "Enter an email";
                    if (!t.contains('@')) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // 🔒 Password
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock,
                      color: scheme.onSurfaceVariant,
                    ),
                    labelText: "Password",
                    labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
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

                // Buttons (Signup + Login)
                _busy
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Signup button: secondary color
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.secondary,
                                  foregroundColor: scheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                icon: const Icon(Icons.person_add),
                                onPressed: _signup,
                                label: const Text("Signup"),
                              ),
                            ),
                          ),

                          // Login button: primary color
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
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

                // Error/status text
                if (_status.isNotEmpty)
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
