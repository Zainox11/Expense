import 'package:flutter/material.dart';

/// Consistent sizing constants used throughout the app.
/// Following an 4px/8px grid system for visual rhythm.
class AppSizes {
  AppSizes._();

  // ──────────────────────────────────────────────
  // Spacing (margins & padding)
  // ──────────────────────────────────────────────

  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;
  static const double s96 = 96.0;
  static const double s120 = 120.0;

  // ──────────────────────────────────────────────
  // Border Radius
  // ──────────────────────────────────────────────

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusRound = 100.0;

  /// Commonly used border radii as BorderRadius objects
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);
  static final BorderRadius borderRadiusXXLarge = BorderRadius.circular(radiusXXLarge);
  static final BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // ──────────────────────────────────────────────
  // Icon Sizes
  // ──────────────────────────────────────────────

  static const double iconXSmall = 14.0;
  static const double iconSmall = 18.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 40.0;
  static const double iconXXLarge = 56.0;

  // ──────────────────────────────────────────────
  // Component Heights
  // ──────────────────────────────────────────────

  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
  static const double cardMinHeight = 80.0;
  static const double fabSize = 56.0;

  // ──────────────────────────────────────────────
  // Common Padding Presets
  // ──────────────────────────────────────────────

  /// Standard screen padding (horizontal)
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: s20);

  /// Standard screen padding (all sides)
  static const EdgeInsets screenPadding = EdgeInsets.all(s20);

  /// Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(s16);

  /// Compact card padding
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(s12);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );

  /// Section padding (vertical space between sections)
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: s24);

  /// Bottom sheet padding
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(s20, s8, s20, s32);

  /// Dialog padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(s24);

  // ──────────────────────────────────────────────
  // Elevation
  // ──────────────────────────────────────────────

  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ──────────────────────────────────────────────
  // Animation Durations (milliseconds)
  // ──────────────────────────────────────────────

  static const int animFast = 200;
  static const int animNormal = 350;
  static const int animSlow = 500;
  static const int animPageTransition = 300;

  // ──────────────────────────────────────────────
  // Max Widths (for responsive layouts)
  // ──────────────────────────────────────────────

  static const double maxContentWidth = 600.0;
  static const double maxTabletWidth = 900.0;
}
