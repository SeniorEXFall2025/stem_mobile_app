import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Pages
import 'pages/auth_page.dart';
import 'pages/welcome_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/events_page.dart';
import 'pages/seed_events_page.dart';
import 'pages/create_event_page.dart';
import 'pages/map_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/favorites_page.dart';

// Fonts
import 'package:google_fonts/google_fonts.dart';

/// App entry point: ensures Firebase is ready before we build the UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// Root widget for the app. Sets global theme + routes,
/// and decides which screen to show based on auth/profile state.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hides the "debug" ribbon in top-right while developing
      debugShowCheckedModeBanner: false,

      // We currently prefer the dark theme; you can switch to .system later
      themeMode: ThemeMode.dark,

      // 🌞 Light theme (mostly for completeness)
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ).copyWith(
              primary: Colors.blue[700],
              secondary: Colors.blueGrey[900],
              onSecondary: Colors.white,
            ),
      ),

      // 🌙 Dark theme (this is what themeMode selects right now)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: Colors.blueGrey[900],
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ).copyWith(
              primary: Colors.blue[400],
              surface: Colors.blueGrey[800],
              secondary: Colors.grey[300],
              onSecondary: Colors.blueGrey[900],
            ),
      ),

      // Centralized named routes. These are easy to push via Navigator.pushNamed().
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/auth': (context) => const AuthPage(),
        '/events': (context) => const EventsPage(),
        '/seed': (context) => const SeedEventsPage(),
        '/create-event': (context) => const CreateEventPage(),
        '/map': (context) => const MapPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/event': (context) => const EventDetailPage(), // basic detail route for now
      }, 
      /// `home` decides the initial screen:
      /// 1) While Firebase Auth is connecting, show a spinner.
      /// 2) If logged in: check if the Firestore profile is complete (role + interests).
      ///    - If incomplete → Onboarding
      ///    - If complete → Welcome
      /// 3) If not logged in → Auth (login/signup)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          // 1) Still connecting to Firebase Auth
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2) Logged in → check Firestore profile completeness
          if (authSnap.hasData) {
            final user = authSnap.data!;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // If user doc missing → force onboarding to collect role/interests
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const OnboardingPage();
                }

                // Validate profile fields
                final data =
                    userSnap.data!.data() as Map<String, dynamic>? ?? {};
                final role = data['role'];
                final interests = (data['interests'] ?? []) as List;

                if (role == null || interests.isEmpty) {
                  return const OnboardingPage();
                }

                // Profile is complete → go to Welcome
                return const WelcomePage();
              },
            );
          }

          // 3) Not logged in → Auth page
          return const AuthPage();
        },
      ),
    );
  }
}
