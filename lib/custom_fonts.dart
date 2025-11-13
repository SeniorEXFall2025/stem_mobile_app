import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// This file defines custom text styles for your app, primarily using the
// DM Sans font from the google_fonts package, which does not require pubspec.yaml declaration.

class CustomFonts {

  // Example: Primary headline style using DM Sans
  static TextStyle headlineStyle(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // Example: Button text style using DM Sans
  static TextStyle buttonTextStyle({Color? color}) {
    return GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: color ?? Colors.white,
    );
  }
}