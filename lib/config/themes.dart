import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';

class AppThemes {
  // Thème clair (principal)
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.accentColor,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Colors.white,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),
    );
  }

  // Thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryColor,
        secondary: AppColors.accentColor,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Color(0xFF121212),
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey[800], thickness: 1),
    );
  }
}
