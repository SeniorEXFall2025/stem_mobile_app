import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Main App Shell
import 'app_shell.dart';

// Pages
import 'pages/welcome_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/events_page.dart';
import 'pages/seed_events_page.dart';
import 'pages/create_event_page.dart';
import 'pages/signup_page.dart';
import 'pages/forgot_password_page8.dart';
import 'pages/login_page6.dart';
import 'pages/about_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/favorites_page.dart';
import 'pages/map_page.dart';
import 'pages/settings_page.dart';

// Auth-related pages

// Fonts
import 'package:google_fonts/google_fonts.dart';

/// Make sure Firebase is ready before we build any UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log early errors to the console so we can see crashes during init.
  FlutterError.onError = (details) => FlutterError.dumpErrorToConsole(details);
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    // Log init failures (common on unsupported desktop platforms) and
    // attempt a safe fallback so the app can still start for debugging.
    debugPrint('Firebase.initializeApp failed: $e\n$st');
    try {
      await Firebase.initializeApp();
    } catch (e2, st2) {
      debugPrint('Fallback Firebase.initializeApp() also failed: $e2\n$st2');
    }
  }

  // Keep Firestore cache enabled so reads don’t block if network is sleepy.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Forces the app to always use the dark theme
      themeMode: ThemeMode.dark,

      // 🌞 Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.blue[700],
          secondary: Colors.blueGrey[900],
          onSecondary: Colors.white,
        ),
      ),

      // 🌙 Dark theme (Now active)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        // Darkest background color: Colors.blueGrey[900]
        scaffoldBackgroundColor: Colors.blueGrey[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          // "Log in" button blue
          primary: Colors.blue[400],
          // Dark blue-grey for surface (e.g., cards/forms)
          surface: Colors.blueGrey[800],
          // Removed deprecated 'background' and 'onBackground' fields
          secondary: Colors.grey[300],
          onSecondary: Colors.blueGrey[900],
        ),
      ),

      // 🧭 App routes
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/events': (context) => const EventsPage(),
        '/seed': (context) => const SeedEventsPage(),
        '/create-event': (context) => CreateEventPage(),
        '/signup': (context) => const SignUpPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/about': (context) => const AboutPage(),
        '/event-detail': (context) => const EventDetailPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/map': (context) => const MapPage(),
        '/settings': (context) => const SettingsPage(),
        '/app-shell': (context) => const AppShell(),
      },

      // 🔄 Auto-redirect based on auth state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snap.hasData || !snap.data!.exists) {
                  return const OnboardingPage();
                }

                final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                final role = data["role"];
                final interests = (data["interests"] ?? []) as List;

                if (role == null || interests.isEmpty) {
                  return const OnboardingPage();
                }

                // Use AppShell for authenticated users with complete profiles
                return const AppShell();
              },
            );
          }
          
          return const LoginPage();
        },
      ),
    );
  }
}