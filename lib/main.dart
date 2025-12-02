import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'package:stem_mobile_app/pages/auth_page.dart';
import 'package:stem_mobile_app/app_shell.dart';
import 'package:stem_mobile_app/pages/onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_mobile_app/pages/forgot_password_page8.dart';
import 'package:stem_mobile_app/pages/about_page.dart';
import 'package:stem_mobile_app/pages/create_event_page.dart';
import 'package:stem_mobile_app/pages/organizations_page.dart'; // NEW
import 'theme_controller.dart';
import 'package:stem_mobile_app/pages/settings_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // assuming curiousBlue and dark975 are defined in custom_colors.dart
  final Color _seedColor = curiousBlue;

  // light theme
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
        labelStyle: TextStyle(color: curiousBlue.shade900),
        hintStyle: TextStyle(color: Colors.grey.shade900),
        floatingLabelStyle: TextStyle(color: curiousBlue.shade900),
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

  // dark theme
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
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        floatingLabelStyle: TextStyle(color: Colors.white),
        prefixStyle: TextStyle(color: Colors.black),
        suffixStyle: TextStyle(color: Colors.black),
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
    // listen for theme changes from ThemeController
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'STEM Mobile App',
          debugShowCheckedModeBanner: false,

          themeMode: mode,
          theme: _lightTheme,
          darkTheme: _darkTheme,

          // named routes used throughout the app
          routes: {
            // root gate (decides between auth flow vs app shell)
            '/': (context) => const AuthGate(),

            // auth / login flow
            '/auth': (context) => const AuthGate(),
            '/onboarding': (context) => const OnboardingPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),

            // app pages
            '/about': (context) => const AboutPage(),
            '/create-event': (context) => const CreateEventPage(),
            '/settings': (context) => const SettingsPage(),
            '/organizations': (context) =>
                const OrganizationsPage(), // NEW route
          },

          initialRoute: '/',

          // fallback for unknown routes
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const AuthGate(),
            );
          },
        );
      },
    );
  }
}

/// the auth gate determines whether to show the AuthPage,
/// the OnboardingPage, or the AppShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;

        // no one is signed in -> show auth screen
        if (user == null) {
          return const AuthPage();
        }

        // user is signed in. now check their profile in Firestore.
        final docStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots();

        return StreamBuilder<DocumentSnapshot>(
          stream: docStream,
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // if there is no profile document yet, send them to onboarding
            if (!profileSnap.hasData || !profileSnap.data!.exists) {
              return const OnboardingPage();
            }

            final data =
                profileSnap.data!.data() as Map<String, dynamic>? ?? {};
            final role = data['role'];
            final interests = (data['interests'] ?? []) as List;

            final bool profileIncomplete = role == null || interests.isEmpty;

            if (profileIncomplete) {
              // signed in but missing role or interests -> onboarding
              return const OnboardingPage();
            }

            // signed in and profile looks complete -> main app shell
            return const AppShell();
          },
        );
      },
    );
  }
}
