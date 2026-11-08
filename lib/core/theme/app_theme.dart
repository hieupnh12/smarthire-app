import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Design Tokens từ DESIGN.md (Luminous Professional)
  static const Color defaultPrimary = Color(0xFF0058BE);
  static const Color defaultSecondary = Color(0xFF505F76);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FD);
  static const Color surfaceContainer = Color(0xFFECEDF7);
  static const Color surfaceContainerHigh = Color(0xFFE6E7F2);
  static const Color onSurface = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF424754);
  static const Color outline = Color(0xFF727785);
  static const Color outlineVariant = Color(0xFFC2C6D6);
  static const Color error = Color(0xFFBA1A1A);

  static Color parseHexColor(String? hexString, {Color fallback = defaultPrimary}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static ThemeData getTheme({Color? dynamicPrimary}) {
    final primaryColor = dynamicPrimary ?? defaultPrimary;

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor.withValues(alpha: 0.15),
      onPrimaryContainer: primaryColor,
      secondary: defaultSecondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
      outline: outline,
      outlineVariant: outlineVariant,
    );

    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineVariant, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: GoogleFonts.inter(
          color: onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
    );
  }
}
