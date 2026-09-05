import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the "night instrument panel" identity: a dark,
/// high-legibility base (this app is used outdoors, often after dark),
/// with two reserved-meaning accents — amber for the idle/armed beacon,
/// and red used *only* for a live emergency so it never loses its alarm
/// value. Teal marks resolved/safe states.
class AppColors {
  AppColors._();

  static const inkBase = Color(0xFF0A0F1A);
  static const inkSurface = Color(0xFF141C2E);
  static const inkSurfaceRaised = Color(0xFF1C2740);
  static const hairline = Color(0x33F2A649);

  static const beaconAmber = Color(0xFFF2A649);
  static const alarmRed = Color(0xFFE1352F);
  static const signalTeal = Color(0xFF2FC7B6);

  static const paper = Color(0xFFF5F1E8);
  static const paperMuted = Color(0xFFB9C0CE);
}

class AppText {
  AppText._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.paper,
          height: 1.05,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.paper,
          height: 1.1,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.paper,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          color: AppColors.paper,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.paperMuted,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.paper,
          letterSpacing: 1.1,
        ),
        labelMedium: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.paperMuted,
          letterSpacing: 0.8,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.paperMuted,
          letterSpacing: 1.4,
        ),
      );

  /// Utility/data face for readouts: coordinates, timestamps, transcripts.
  static TextStyle mono({
    double fontSize = 13,
    Color color = AppColors.paperMuted,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.ibmPlexMono(fontSize: fontSize, color: color, fontWeight: weight);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.inkBase,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.inkSurface,
      primary: AppColors.beaconAmber,
      secondary: AppColors.signalTeal,
      error: AppColors.alarmRed,
    ),
    textTheme: AppText.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.inkBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.paper),
    ),
    cardTheme: CardThemeData(
      color: AppColors.inkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.hairline, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.beaconAmber,
        foregroundColor: AppColors.inkBase,
        textStyle: AppText.textTheme.labelLarge?.copyWith(color: AppColors.inkBase),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.paper,
        side: const BorderSide(color: AppColors.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.beaconAmber, width: 1.5),
      ),
      labelStyle: AppText.textTheme.bodyMedium,
      hintStyle: AppText.textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inkSurfaceRaised,
      contentTextStyle: AppText.textTheme.bodyLarge,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
