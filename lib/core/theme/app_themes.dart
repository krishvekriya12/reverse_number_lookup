import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    cardColor: const Color(0xFFF1F5F9),
    dividerColor: const Color(0xFFE2E8F0),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0066FF),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF101410),
    cardColor: const Color(0xFF1E231E),
    dividerColor: const Color(0xFF40493F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2979FF),
      surface: Color(0xFF111310),
      onSurface: Color(0xFFF7FBF2),
      onSurfaceVariant: Color(0xFFBFC9BB),
      outline: Color(0xFF40493F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF101410),
      foregroundColor: Color(0xFFF7FBF2),
      elevation: 0,
    ),
  );
}
