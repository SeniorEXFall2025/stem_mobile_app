import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_page.dart';
import 'forgot_password_page8.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait for the auth state to reflect the signed-in user.
      await FirebaseAuth.instance.userChanges().firstWhere(
            (u) => u != null && u.uid == cred.user!.uid,
          );

      // Ensure a Firestore profile exists. If not, create one and route to onboarding.
      final uid = cred.user?.uid;
      if (uid != null) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final snap = await docRef.get();
        if (!snap.exists) {
          await docRef.set({
            'role': null,
            'interests': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
          return;
        } else {
          final data = snap.data() ?? <String, dynamic>{};
          final role = data['role'];
          final interests = (data['interests'] ?? []) as List;
          if (role == null || interests.isEmpty) {
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
            return;
          }
        }
      }

      if (!mounted) return;
      _usernameController.clear();
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged in as ${cred.user?.email ?? 'unknown'}')),
      );

    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code} ${e.message}');
      debugPrintStack(label: 'login stack', stackTrace: StackTrace.current);
      final msg = 'Login error [${e.code}]: ${e.message}';
      if (mounted) setState(() => _status = msg);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('Exception during login: $e');
      debugPrintStack(label: 'login stack', stackTrace: StackTrace.current);
      final msg = 'Login error: $e';
      if (mounted) setState(() => _status = msg);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Welcome",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sign in to continue",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          labelText: 'Email',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[300],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                        validator: (val) {
                          final t = val?.trim() ?? '';
                          if (t.isEmpty) return 'Enter an email';
                          if (!t.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          labelText: 'Password',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[300],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter a password';
                          if (val.length < 6) return 'Min 6 characters required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelText: 'Password',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[300],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (_status.isNotEmpty)
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.redAccent),
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.poppins(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
