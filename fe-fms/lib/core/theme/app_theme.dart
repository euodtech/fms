import 'package:flutter/material.dart';

import 'dispatch_palette.dart';

/// Defines the application's theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const primary = Color(0xFF1B63FF); // clean blue
    const surface = Color(0xFFF7F8FA);
    const text = Color(0xFF0F172A);
    const subtleText = Color(0xFF64748B);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: text,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      textTheme: Typography.blackMountainView.copyWith(
        bodyMedium: const TextStyle(color: subtleText, height: 1.25),
        bodyLarge: const TextStyle(color: text, height: 1.3),
        titleMedium: const TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      extensions: const <ThemeExtension<dynamic>>[DispatchPalette.light],
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    const primary = Color(0xFF4D86FF); // lifted blue, legible on dark
    const surface = Color(0xFF0F141A);
    const card = Color(0xFF1A222C);
    const text = Color(0xFFE8EBF0);
    const subtleText = Color(0xFF94A3B8);
    const border = Color(0xFF2A3441);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: card,
        foregroundColor: text,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      textTheme: Typography.whiteMountainView.copyWith(
        bodyMedium: const TextStyle(color: subtleText, height: 1.25),
        bodyLarge: const TextStyle(color: text, height: 1.3),
        titleMedium: const TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      extensions: const <ThemeExtension<dynamic>>[DispatchPalette.dark],
      useMaterial3: true,
    );
  }
}
