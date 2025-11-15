import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'package:stem_mobile_app/pages/auth_page.dart';
import 'package:stem_mobile_app/app_shell.dart';
import 'package:stem_mobile_app/pages/onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_mobile_app/pages/forgot_password_page8.dart';
import 'package:stem_mobile_app/pages/about_page.dart';
import 'package:stem_mobile_app/pages/create_event_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // NOTE: Assuming curiousBlue and dark975 are correctly defined in custom_colors.dart
  final Color _seedColor = curiousBlue;

  // Light Theme Configuration
  ThemeData get _lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        primary: curiousBlue,
        secondary: curiousBlue.shade700,
        background: Colors.white,
        onBackground: Colors.black,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        // Controls the color of the text the user types (making labels darker)
        labelStyle: TextStyle(color: curiousBlue.shade900),
        hintStyle: TextStyle(color: Colors.grey.shade900),
        floatingLabelStyle: TextStyle(color: curiousBlue.shade900),

        // Ensure input text itself is black regardless of field color
        prefixStyle: const TextStyle(color: Colors.black),
        suffixStyle: const TextStyle(color: Colors.black),
        helperStyle: const TextStyle(color: Colors.black54),
        counterStyle: const TextStyle(color: Colors.black54),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  // Dark Theme Configuration
  ThemeData get _darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        primary: curiousBlue.shade300,
        secondary: curiousBlue.shade400,
        background: dark975,
        onBackground: Colors.white,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: const InputDecorationTheme(
        // These are light, appropriate for dark mode backgrounds
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        floatingLabelStyle: TextStyle(color: Colors.white),

        // Input text must be black for white input fields
        prefixStyle: TextStyle(color: Colors.black),
        suffixStyle: TextStyle(color: Colors.black54),
        helperStyle: TextStyle(color: Colors.black54),
        counterStyle: TextStyle(color: Colors.black54),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: dark975,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: dark975,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STEM Mobile App',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,

      // Named routes used throughout the app
      routes: {
        // Root gate (decides between auth flow vs app shell)
        '/': (context) => const AuthGate(),

        // Auth / login flow
        '/auth': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),

        // App pages
        '/about': (context) => const AboutPage(),
        '/create-event': (context) => const CreateEventPage(),
      },

      initialRoute: '/',

      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthGate(),
        );
      },
    );
  }
}

/// The Auth Gate determines whether to show the AuthPage or the AppShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // User is not signed in
          return const AuthPage();
        }

        // User is signed in
        return const AppShell();
      },
    );
  }
}
