import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../custom_colors.dart' as app_colors;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
      Future.delayed(const Duration(milliseconds: 500), () => Navigator.pop(context));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error sending reset email')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color primaryAccentColor = app_colors.curiousBlue.shade900;
    const Color onPrimaryColor = Colors.white;

    // Theme-aware input field styling
    final Color inputFieldFillColor = isDarkMode
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final Color inputFieldTextColor = isDarkMode
        ? Colors.white
        : Colors.black;

    return Scaffold(
      // Use scaffoldBackgroundColor for the background
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? scheme.surfaceContainerLow : scheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Forgot Password",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryAccentColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant, // Subdued text color
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: inputFieldTextColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFieldFillColor,
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : primaryAccentColor,
                    ),
                    floatingLabelStyle: TextStyle(color: primaryAccentColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccentColor,
                      foregroundColor: onPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator(
                      color: onPrimaryColor,
                      strokeWidth: 2,
                    )
                        : Text(
                      'Send Reset Link',
                      // STYLED: Use standard theme text
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Back to Login",
                    // STYLED: Use primary accent color
                    style: TextStyle(
                      color: primaryAccentColor,
                      fontWeight: FontWeight.w600,
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