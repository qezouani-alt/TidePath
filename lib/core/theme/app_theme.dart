import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ocean = Color(0xFF07527A);
  static const deep = Color(0xFF063C59);
  static const blue = Color(0xFF0866A8);
  static const aqua = Color(0xFF16B8C4);
  static const glow = Color(0xFF9AF5E6);
  static const mist = Color(0xFFEAF7FC);
  static const canvas = Color(0xFFF5F9FB);
  static const ink = Color(0xFF102A3A);
  static const muted = Color(0xFF728897);
  static const good = Color(0xFF1CA889);
  static const warning = Color(0xFFE79B4A);
}

abstract final class AppTheme {
  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);

  static ThemeData _make(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF123044) : Colors.white;
    final canvas = dark ? const Color(0xFF081F2E) : AppColors.canvas;
    final ink = dark ? const Color(0xFFF1FAFD) : AppColors.ink;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: brightness,
        surface: surface,
      ),
      fontFamily: 'SF Pro Display',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -.8,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: ink),
        bodyMedium: TextStyle(fontSize: 13, color: ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}
