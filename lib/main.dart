import 'dart:ui' as ui; // PlatformDispatcher.onError

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'app_shell.dart';
import 'custom_colors.dart';

// Pages
import 'pages/auth_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/events_page.dart';
import 'pages/seed_events_page.dart';
import 'pages/create_event_page.dart';
import 'pages/map_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/favorites_page.dart';
import 'pages/about_page.dart';

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Keep Firestore cache enabled so reads don’t block if network is sleepy.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

/// Root widget: provides theme, routes, and decides first screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Prefer dark for now.
      themeMode: ThemeMode.dark,

      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: light100,
        colorScheme:
            ColorScheme.fromSwatch(
              primarySwatch: curiousBlue,
              brightness: Brightness.light,
            ).copyWith(
              primary: curiousBlue.shade600,
              secondary: curiousBlue.shade900,
              surface: light50,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
            ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: dark975,
        colorScheme:
            ColorScheme.fromSwatch(
              primarySwatch: curiousBlue,
              brightness: Brightness.dark,
            ).copyWith(
              primary: curiousBlue.shade400,
              surface: dark950,
              secondary: Colors.grey[300],
              onSecondary: dark950,
            ),
      ),

      // Named routes
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/auth': (context) => const AuthPage(),
        '/events': (context) => const EventsPage(),
        '/seed': (context) => const SeedEventsPage(),
        '/create-event': (context) => const CreateEventPage(),
        '/map': (context) => const MapPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/event': (context) => const EventDetailPage(),
        '/about': (context) => const AboutPage(),
      },

      /// Initial screen logic:
      /// 1) While Auth connects → spinner
      /// 2) If logged in → watch Firestore user doc as a stream
      ///    - missing/incomplete profile → Onboarding
      ///    - complete → AppShell
      /// 3) If logged out → Auth
      ///
      /// Note: use `userChanges()` instead of `authStateChanges()` so we get
      /// token refresh + profile changes cleanly.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, authSnap) {
          // 1) waiting on Auth
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const _CenteredSpinner();
          }

          // 2) logged in → listen to user doc
          if (authSnap.hasData) {
            final user = authSnap.data!;
            final stream = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots();

            return StreamBuilder<DocumentSnapshot>(
              stream: stream,
              builder: (context, userSnap) {
                if (userSnap.hasError) {
                  return _ErrorScaffold(
                    message: 'Profile load failed:\n${userSnap.error}',
                    onRetry: () => (context as Element).markNeedsBuild(),
                  );
                }
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const _CenteredSpinner();
                }

                // No doc yet → Onboarding
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const OnboardingPage();
                }

                // Check required fields
                final data =
                    (userSnap.data!.data() as Map<String, dynamic>?) ?? {};
                final role = data['role'];
                final interests = (data['interests'] ?? []) as List;

                if (role == null || interests.isEmpty) {
                  return const OnboardingPage();
                }

                // All good → main app
                return const AppShell();
              },
            );
          }

          // 3) logged out → Auth
          return const AuthPage();
        },
      ),
    );
  }
}

/// Small centered spinner we reuse.
class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Simple error screen with a retry button.
class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
