import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color brand = Color(0xFF153059);
  static const Color brand700 = Color(0xFF1E4177);
  static const Color brand050 = Color(0xFFEAF0F9);

  // Backgrounds & Surfaces
  static const Color bg = Color(0xFFF5F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunk = Color(0xFFFAFBFC);

  // Borders
  static const Color border = Color(0xFFE6E9EF);
  static const Color borderStrong = Color(0xFFD7DBE3);

  // Text & Ink
  static const Color ink900 = Color(0xFF12172A);
  static const Color ink700 = Color(0xFF3A4256);
  static const Color ink500 = Color(0xFF6B7286);
  static const Color ink400 = Color(0xFF9AA1B2);

  // Semantics
  static const Color money = Color(0xFF0E9B6C);
  static const Color money050 = Color(0xFFE4F7EF);
  
  static const Color amber = Color(0xFFB4740F);
  static const Color amber050 = Color(0xFFFBF1DF);
  
  static const Color coral = Color(0xFFD14343);
  static const Color coral050 = Color(0xFFFCEAEA);
  
  static const Color violet = Color(0xFF6C5CE0);
  static const Color violet050 = Color(0xFFEFECFC);

  // Keeping old aliases to prevent breaking other files immediately
  static const Color primary = brand;
  static const Color primaryLight = brand050;
  static const Color textPrimary = ink900;
  static const Color textSecondary = ink700;
  static const Color background = bg;
  static const Color success = money;
  static const Color successBg = money050;
  static const Color warning = amber;
  static const Color warningBg = amber050;
  static const Color error = coral;
  static const Color errorBg = coral050;
  
  // Re-add missing aliases
  static const Color textOnPrimary = surface;
  static const Color secondary = violet;
  static const Color surfaceAlt = surfaceSunk;
  static const Color textDisabled = ink400;
  static const Color info = brand;
  static const Color infoBg = brand050;
}
