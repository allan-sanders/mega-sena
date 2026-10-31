import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Dark Premium & Verde Esmeralda / Neon
  static const Color bgPrimary = Color(0xFF070D0A);
  static const Color bgSecondary = Color(0xFF0E1A14);
  static const Color surfaceCard = Color(0xFF13241B);
  static const Color surfaceGlass = Color(0x1FFFFFFF);
  static const Color neonEmerald = Color(0xFF00E676);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldDeep = Color(0xFF047857);
  static const Color goldHighlight = Color(0xFFFBBF24);
  static const Color warmCoral = Color(0xFFFF6B6B);
  static const Color coolCyan = Color(0xFF38BDF8);
  static const Color textPrimary = Color(0xFFF0FDF4);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color borderSubtle = Color(0xFF1F382B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: neonEmerald,
      colorScheme: const ColorScheme.dark(
        primary: neonEmerald,
        secondary: emeraldAccent,
        surface: surfaceCard,
        onPrimary: Color(0xFF042F1A),
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonEmerald,
          foregroundColor: const Color(0xFF032212),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: emeraldAccent, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
