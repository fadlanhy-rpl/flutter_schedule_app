import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBlue = Color(0xFF0D1B2A);
  static const Color mediumBlue = Color(0xFF1B263B);
  static const Color lightBlue = Color(0xFF415A77);
  static const Color accentYellow = Color(0xFFFFD60A);
  static const Color textWhite = Color(0xFFE0E1DD);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: lightBlue,
        surface: mediumBlue,
        onSurface: textWhite,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: accentYellow,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentYellow,
        foregroundColor: darkBlue,
      ),
      cardTheme: CardThemeData(
        color: mediumBlue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mediumBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentYellow, width: 2),
        ),
      ),
    );
  }
}
