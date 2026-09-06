import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app-wide light "personal companion" palette — warm cream
/// background, indigo/teal accents, crimson reserved for danger/SOS.
class HomeColors {
  HomeColors._();

  static const appBg = Color(0xFFF8F7F4);
  static const cardBorder = Color(0xFFEFECE6);
  static const textPrimary = Color(0xFF1E2935);
  static const textSecondary = Color(0xFF6B7280);
  static const brandIndigo = Color(0xFF273C5A);
  static const brandTeal = Color(0xFF4E8B82);
  static const statusGreen = Color(0xFF5B9B72);
  static const caution = Color(0xFFC98A3F);
  static const sosCrimson = Color(0xFFC94C5B);
  static const sosCrimsonDark = Color(0xFFB53D4C);
  static const inactiveNav = Color(0xFF9CA3AF);
}

class HomeText {
  HomeText._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = HomeColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle greeting({Color color = HomeColors.textPrimary}) =>
      _base(size: 22, weight: FontWeight.w700, color: color, letterSpacing: -0.3);

  static TextStyle title({Color color = HomeColors.textPrimary}) =>
      _base(size: 17, weight: FontWeight.w700, color: color, letterSpacing: -0.2);

  static TextStyle cardTitle({Color color = HomeColors.textPrimary}) =>
      _base(size: 15, weight: FontWeight.w600, color: color);

  static TextStyle body({Color color = HomeColors.textSecondary}) =>
      _base(size: 13.5, weight: FontWeight.w500, color: color, height: 1.35);

  static TextStyle caption({Color color = HomeColors.textSecondary}) =>
      _base(size: 12, weight: FontWeight.w500, color: color);

  static TextStyle eyebrow({Color color = HomeColors.textSecondary}) =>
      _base(size: 11.5, weight: FontWeight.w700, color: color, letterSpacing: 0.8);

  static TextStyle navLabel({required bool active}) => _base(
        size: 11,
        weight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? HomeColors.brandIndigo : HomeColors.inactiveNav,
      );
}
