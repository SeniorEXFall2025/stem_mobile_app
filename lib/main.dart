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
import 'package:stem_mobile_app/pages/organizations_page.dart';
import 'theme_controller.dart';
import 'package:stem_mobile_app/pages/settings_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global instance for local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Local Notification Helper Functions

Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showLocalNotification(RemoteMessage message) async {
  if (message.notification == null) return;

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important event notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

  const NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails, iOS: iOSDetails);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode, // Unique ID for the notification
    message.notification!.title,
    message.notification!.body,
    platformDetails,
    payload: message.data.toString(),
  );
}



Future<String?> setupFCM() async {
  await initializeLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request Permissions (This triggers the system prompt)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Handle Foreground Messages: show local notification if app is open
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      showLocalNotification(message);
    }
  });

  // Handle message when app is opened from a terminated state
  await messaging.getInitialMessage();

  // Return the token to be saved later upon successful authentication
  return await messaging.getToken();
}


// Global variable to hold the FCM token
String? fcmToken;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  fcmToken = await setupFCM();

  runApp(const MyApp());
}


Future<void> saveTokenToDatabase(String? token, String userId) async {
  if (token == null) return;

  // Get the current token from Firestore to avoid unnecessary writes
  final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
  final docSnap = await userDoc.get();

  if (docSnap.exists) {
    final existingToken = docSnap.data()?['fcmToken'];

    // Only update if the token has changed
    if (existingToken != token) {
      await userDoc.set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  } else {
    // If user profile doesn't exist yet (before onboarding), save it later
    // or rely on the onboarding process to merge this data.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Color _seedColor = curiousBlue;

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'STEM Mobile App',
          debugShowCheckedModeBanner: false,

          themeMode: mode,
          theme: _lightTheme,
          darkTheme: _darkTheme,

          routes: {
            '/': (context) => const AuthGate(),
            '/auth': (context) => const AuthGate(),
            '/onboarding': (context) => const OnboardingPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/about': (context) => const AboutPage(),
            '/create-event': (context) => const CreateEventPage(),
            '/settings': (context) => const SettingsPage(),
            '/organizations': (context) =>
            const OrganizationsPage(),
          },

          initialRoute: '/',

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

        if (user == null) {
          return const AuthPage();
        }

        // Save the generated token to the authenticated user's profile
        if (fcmToken != null) {
          saveTokenToDatabase(fcmToken, user.uid);
        }

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

            if (!profileSnap.hasData || !profileSnap.data!.exists) {
              return const OnboardingPage();
            }

            final data =
                profileSnap.data!.data() as Map<String, dynamic>? ?? {};
            final role = data['role'];
            final interests = (data['interests'] ?? []) as List;

            final bool profileIncomplete = role == null || interests.isEmpty;

            if (profileIncomplete) {
              return const OnboardingPage();
            }

            return const AppShell();
          },
        );
      },
    );
  }
}