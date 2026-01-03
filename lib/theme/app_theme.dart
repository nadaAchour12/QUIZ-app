import 'package:flutter/material.dart';


class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    primaryColor: const Color(0xFF1EB9F0),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1B2A),
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1EB9F0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    cardTheme: CardThemeData(
      color: Color(0xFF16263E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),

  );
}
