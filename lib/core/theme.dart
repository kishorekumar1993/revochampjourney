import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class RevoTheme {
  static bool isDark = true;

  static Color get background => isDark ? const Color(0xFF0F0F1B) : const Color(0xFFF8FAFC);
  static Color get sidebarBackground => isDark ? const Color(0xFF0A0A12) : const Color(0xFFFFFFFF);
  static Color get cardBg => isDark ? const Color(0x1F2A2A40) : const Color(0xFFFFFFFF);
  static Color get cardBorder => isDark ? const Color(0x33A086FA) : const Color(0xFFE2E8F0);
  
  static Color get primary => isDark ? const Color(0xFF7C3AED) : const Color(0xFF6366F1);
  static Color get primaryLight => isDark ? const Color(0xFFA78BFA) : const Color(0xFF818CF8);
  static Color get secondary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get accent => isDark ? const Color(0xFF06B6D4) : const Color(0xFF0891B2);
  
  static Color get textPrimary => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
  static Color get error => const Color(0xFFEF4444);
  static Color get success => const Color(0xFF10B981);
  static Color get warning => const Color(0xFFF59E0B);

  static ThemeData getThemeData(bool dark) {
    isDark = dark;
    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: dark
          ? const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              secondary: Color(0xFF10B981),
              surface: Color(0x1F2A2A40),
              error: Color(0xFFEF4444),
              onPrimary: Colors.white,
              onSurface: Color(0xFFF3F4F6),
            )
          : const ColorScheme.light(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFF059669),
              surface: Color(0xFFFFFFFF),
              error: Color(0xFFEF4444),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0x12FFFFFF) : const Color(0xFFF1F5F9),
        hintStyle: TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: TextStyle(color: textPrimary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? const Color(0x22A086FA) : const Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }

  // Helper widget to render premium Glassmorphism look
  static Widget glassmorphicContainer({
    Key? key,
    required Widget child,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    double? width,
    double? height,
    BoxBorder? border,
  }) {
    return Container(
      key: key,
      width: width,

      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
