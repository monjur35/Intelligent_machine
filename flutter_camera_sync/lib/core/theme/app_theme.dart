import 'package:flutter/material.dart';

class AppTheme {
  // Futuristic dark telemetry palette matching Assessment Screenshot
  static const Color darkBg = Color(0xFF0A0F1D);
  static const Color cardBg = Color(0xFF131C31);
  static const Color surfaceBorder = Color(0xFF1E293B);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0xFF22D3EE);

  // Status Badge Colors
  static const Color statusQueued = Color(0xFF94A3B8);
  static const Color statusSyncing = Color(0xFF38BDF8);
  static const Color statusSynced = Color(0xFF10B981);
  static const Color statusFailed = Color(0xFFF43F5E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: cyanAccent,
      colorScheme: const ColorScheme.dark(
        primary: cyanAccent,
        secondary: cyanGlow,
        surface: cardBg,
        error: statusFailed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: roundedCornerShape(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: roundedCornerShape(24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static RoundedRectangleBorder roundedCornerShape(double radius) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: surfaceBorder, width: 1),
    );
  }
}
