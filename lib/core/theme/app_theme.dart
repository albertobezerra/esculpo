import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    primaryColor: const Color(0xFF9D291A), // Vermelho-Terra
    scaffoldBackgroundColor: const Color(0xFF4A4A4A), // Cinza Pedra Escuro
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9D291A),
      secondary: Color(0xFFE07A5F), // Laranja Quente
      surface: Color(0xFFF5F5F0), // Branco Creme
      onPrimary: Color(0xFFF5F5F0),
      onSecondary: Color(0xFF4A4A4A),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF5F5F0)), // Branco Creme
      bodyMedium: TextStyle(color: Color(0xFFB0B0B0)), // Cinza Pedra Claro
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9D291A),
        foregroundColor: const Color(0xFFF5F5F0),
      ),
    ),
  );
}
