import 'package:flutter/material.dart';

import 'home_theme.dart';

/// The MaterialApp root theme — built from [HomeColors]/[HomeText] so that
/// default, unstyled widget behavior (ripples, selection handles, dialog
/// fallbacks) matches the light "personal companion" look used everywhere
/// in the app, not a vestigial dark theme nothing actually renders with.
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: HomeColors.appBg,
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.white,
      primary: HomeColors.brandIndigo,
      secondary: HomeColors.brandTeal,
      error: HomeColors.sosCrimson,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: HomeColors.textPrimary,
      displayColor: HomeColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: HomeColors.appBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: HomeText.title(),
      iconTheme: const IconThemeData(color: HomeColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HomeColors.cardBorder, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: HomeColors.cardBorder, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HomeColors.brandIndigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HomeColors.textPrimary,
        side: const BorderSide(color: HomeColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HomeColors.appBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HomeColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HomeColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HomeColors.brandIndigo, width: 1.5),
      ),
      labelStyle: HomeText.body(),
      hintStyle: HomeText.body(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: HomeColors.brandIndigo,
      contentTextStyle: HomeText.body(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
