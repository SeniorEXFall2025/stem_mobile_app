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



// Fonts
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/auth': (context) => const AuthPage(),
        '/events': (context) => const EventsPage(),
        '/seed': (context) => const SeedEventsPage(),
        '/create-event': (context) => CreateEventPage(),
      },

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

                return const WelcomePage();
              },
            );
          }

          return const AuthPage();
        },
      ),
    );
  }
}