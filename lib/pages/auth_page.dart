import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_mobile_app/custom_colors.dart';

/// Simple email/password auth screen.
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
  bool _busy = false;  // shows a spinner while hitting Firebase

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Create a new account, make a profile doc, then onboard
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

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

      await FirebaseAuth.instance.userChanges().firstWhere(
            (u) => u != null && u.uid == cred.user!.uid,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .set({
        "role": null,
        "interests": <String>[],
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed up as ${cred.user?.email ?? 'unknown'}'),
        ),
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    } on FirebaseAuthException catch (e) {
      final msg = 'Signup error [${e.code}]: ${e.message}';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
      }
    } catch (e) {
      final msg = 'Signup error: $e';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Log in existing user
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

      await FirebaseAuth.instance.userChanges().firstWhere(
            (u) => u != null && u.uid == cred.user!.uid,
      );

      if (!mounted) return;

      _email.clear();
      _password.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in as ${cred.user?.email ?? 'unknown'}'),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.of(context).pushReplacementNamed('/');
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/');
    } on FirebaseAuthException catch (e) {
      final msg = 'Login error [${e.code}]: ${e.message}';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
      }
    } catch (e) {
      final msg = 'Login error: $e';
      if (mounted) {
        setState(() => _status = "🔥 $msg");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color deepBlueBackground = theme.scaffoldBackgroundColor;

    final Color unfocusedBorderColor = Colors.grey.shade400;

    final Color logoTextColor = theme.brightness == Brightness.dark
        ? Colors.white
        : curiousBlue.shade900;

    final Color linkTextColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.8)
        : curiousBlue.shade900.withOpacity(0.9);


    final Color appBarTextColor = theme.brightness == Brightness.dark
        ? scheme.onPrimary
        : curiousBlue.shade900;

    final Color deepBlueBackground = theme.scaffoldBackgroundColor;

    final Color mainBlueColor = scheme.primary;

    final Color unfocusedBorderColor = Colors.grey.shade400;

    return Scaffold(
      backgroundColor: deepBlueBackground,

      backgroundColor: deepBlueBackground,

      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: deepBlueBackground,
        foregroundColor: scheme.onPrimary,

        title: Text(
          "Login",
          style: TextStyle(color: appBarTextColor),
        ),
        backgroundColor: deepBlueBackground,
        foregroundColor: appBarTextColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 50),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/co_stem_logo_transparent.png',
                    height: 160,
                  ),
                ),
              ),

              // CO STEM Ecosystem (Color changes based on theme)
              Center(
                child: Text(
                  "CO STEM Ecosystem",
                  style: TextStyle(
                    color: logoTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 50),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/images/co_stem_logo.png',
                    height: 160,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              ),
              const SizedBox(height: 50),

              // Email Input
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: unfocusedBorderColor,
                        width: 1.0), // <- ADDED BORDER
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: scheme.secondary, width: 2.0),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                validator: (val) {
                  final t = val?.trim() ?? '';
                  if (t.isEmpty) return "Enter an email";
                  if (!t.contains('@')) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Password Input
              TextFormField(
                controller: _password,
                obscureText: true,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                        color: unfocusedBorderColor,
                        width: 1.0), // <- ADDED BORDER
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: scheme.secondary, width: 2.0),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter a password";
                  if (val.length < 6) return "Min 6 characters required";
                  return null;
                },
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Password reset functionality coming soon!")),
                    );
                  },
                  child: Text(
                    "Forgot Password Link",
                    style: TextStyle(
                        color: scheme.onPrimary.withAlpha(204), fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Buttons
              _busy
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: curiousBlue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text("Log in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Register button (Light Blue background, Deep Blue text/border)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: curiousBlue.shade50,
                        foregroundColor: curiousBlue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: curiousBlue.shade900, width: 2),
                        ),
                      ),
                      onPressed: _signup,
                      child: const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Buttons
              _busy
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainBlueColor,
                              foregroundColor: scheme.onPrimary, // White text
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text("Log in",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: mainBlueColor, // Blue text
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                // Blue border for distinction
                                side:
                                    BorderSide(color: mainBlueColor, width: 2),
                              ),
                            ),
                            onPressed: _signup,
                            child: const Text("Register",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}
