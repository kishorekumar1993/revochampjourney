import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RunnerTheme {
  static const brand = Color(0xFF5B4FCF);
  static const brandLight = Color(0xFF7C72E0);
  static const brandSurface = Color(0xFFEEECFD);
  static const bg = Color(0xFFF0F0FF);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const textLight = Color(0xFFB0B4C8);
  static const border = Color(0xFFE4E6F0);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const inputBg = Color(0xFFFAFAFF);
  static const leftPanelBg = Color(0xFFF7F5FF);
  static const dividerColor = Color(0xFFF0F0FF);

  static const double mobileBreak = 640;
}

InputDecoration buildRunnerInputDecoration({
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
  String? error,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13, color: RunnerTheme.textLight),
    labelStyle: GoogleFonts.poppins(
      fontSize: 12,
      color: RunnerTheme.textMid,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.poppins(
      fontSize: 12,
      color: RunnerTheme.brand,
      fontWeight: FontWeight.w600,
    ),
    errorText: error,
    errorStyle: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.error),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: RunnerTheme.inputBg,
    isDense: dense,
    contentPadding: dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RunnerTheme.border, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RunnerTheme.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RunnerTheme.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RunnerTheme.error, width: 1.5),
    ),
  );
}
