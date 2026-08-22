import 'package:flutter/material.dart';

class AppColors {
  // Brand (spec: --color-primary: #1E5FB0)
  static const Color brand = Color(0xFF1E5FB0);
  static const Color brandDark = Color(0xFF144A8C);
  static const Color brand050 = Color(0xFFE8F0FB);

  // Backgrounds & Surfaces (spec: --color-bg: #F7F8FA)
  static const Color bg = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunk = Color(0xFFF0F2F5);

  // Borders (spec: --color-border: #D7DCE2)
  static const Color border = Color(0xFFD7DCE2);
  static const Color borderStrong = Color(0xFFBEC4CE);

  // Text (spec: --color-text-primary: #1A1D21, never light gray)
  static const Color ink900 = Color(0xFF1A1D21);
  static const Color ink700 = Color(0xFF4B5259); // AA compliant on white
  static const Color ink500 = Color(0xFF6B7280); // Used sparingly
  static const Color ink400 = Color(0xFF9CA3AF);

  // Semantics (spec: green=money/success, red=danger, orange=warning)
  static const Color money = Color(0xFF1E8A3C);   // spec: --color-success
  static const Color money050 = Color(0xFFE4F5EA);

  static const Color amber = Color(0xFFE08A00);   // spec: --color-warning
  static const Color amber050 = Color(0xFFFFF3DC);

  static const Color coral = Color(0xFFC62828);   // spec: --color-danger
  static const Color coral050 = Color(0xFFFCE8E8);

  static const Color violet = Color(0xFF5E4FD4);
  static const Color violet050 = Color(0xFFEEECFA);

  // ---- Stable aliases used throughout the app ----
  static const Color primary = brand;
  static const Color primaryDark = brandDark;
  static const Color primaryLight = brand050;
  // Legacy alias kept for backward compat with dashboard
  static const Color brand700 = brandDark;
  static const Color textPrimary = ink900;
  static const Color textSecondary = ink700;
  static const Color background = bg;
  static const Color success = money;
  static const Color successBg = money050;
  static const Color warning = amber;
  static const Color warningBg = amber050;
  static const Color error = coral;
  static const Color errorBg = coral050;
  static const Color textOnPrimary = surface;
  static const Color secondary = violet;
  static const Color surfaceAlt = surfaceSunk;
  static const Color textDisabled = ink400;
  static const Color info = brand;
  static const Color infoBg = brand050;
}
