import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF0A84FF);
  static const Color accentColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);

  // Aliases for better semantics
  static const Color primary = primaryColor;
  static const Color success = accentColor;
  static const Color warning = warningColor;
  static const Color danger = errorColor;
  static const Color info = Color(0xFF5AC8FA);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
}

class AppSizes {
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double pagePadding = 16.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;
  static const double iconSize = 24.0;
}
