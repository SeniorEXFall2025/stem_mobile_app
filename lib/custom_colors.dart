import 'package:flutter/material.dart';

// This file contains the colors from the discord resources page.
// Should be enough to match the color scheme of the web teams project
const int _curiousBluePrimaryValue = 0xFF218DD6;

// CustomColors.curiousBlue[400]
const MaterialColor curiousBlue = MaterialColor(
  _curiousBluePrimaryValue,
  <int, Color>{
    50: Color(0xFFf1f8fe),
    100: Color(0xFFe3effb),
    200: Color(0xFFc0dff7),
    300: Color(0xFF88c5f1),
    400: Color(0xFF3da2e6),
    500: Color(_curiousBluePrimaryValue),
    600: Color(0xFF1370b6),
    700: Color(0xFF115993),
    800: Color(0xFF124c7a),
    900: Color(0xFF144066),
    950: Color(0xFF0e2943),
  },
);


// Light Mode Neutrals
const Color light50 = Color(0xFFffffff); // Pure White
const Color light100 = Color(0xFFfafafa);
const Color light200 = Color(0xFFf4f4f5);

// Dark Mode Neutrals
const Color dark900 = Color(0xFF000000); // Pure Black
const Color dark950 = Color(0xFF0e0e11);
const Color dark975 = Color(0xFF18181b);