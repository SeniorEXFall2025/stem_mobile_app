import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'package:stem_mobile_app/pages/auth_page.dart';
import 'package:stem_mobile_app/app_shell.dart';
import 'package:stem_mobile_app/pages/onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_mobile_app/pages/forgot_password_page8.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Color _seedColor = curiousBlue;

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
        labelStyle: TextStyle(color: curiousBlue.shade900),

        hintStyle: TextStyle(color: Colors.grey.shade900),

        floatingLabelStyle: TextStyle(color: curiousBlue.shade900),

        prefixStyle: const TextStyle(color: Colors.black),
        suffixStyle: const TextStyle(color: Colors.black),
        helperStyle: const TextStyle(color: Colors.black54),
        counterStyle: const TextStyle(color: Colors.black54),
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
      // Use DM Sans Text Theme
      textTheme: GoogleFonts.dmSansTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }
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
      appBarTheme: const AppBarTheme(
        backgroundColor: dark975,
        foregroundColor: Colors.white,
        elevation: 0,
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
    return MaterialApp(
      title: 'STEM Mobile App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routes: {
        '/': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingPage(),
      },
      initialRoute: '/',
    );
    return MaterialApp(
      title: 'STEM Mobile App',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,

      routes: {
        '/': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
      initialRoute: '/',
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
