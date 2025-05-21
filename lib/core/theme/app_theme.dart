import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.roboto(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: const Color(0xFFF5F5F0),
      ),
      headlineMedium: GoogleFonts.bebasNeue(
        fontSize: 32,
        color: const Color(0xFF9D291A), // Usado pra títulos grandes e logo
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 16,
        color: const Color(0xFFB0B0B0),
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 14,
        color: const Color(0xFFB0B0B0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9D291A),
        foregroundColor: const Color(0xFFF5F5F0),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.roboto(
        color: const Color(0xFFB0B0B0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F0).withValues(alpha: 0.8),
    ),
  );
}
