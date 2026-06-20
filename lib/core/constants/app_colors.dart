import 'package:flutter/material.dart';

/// Premium color palette for the Expense Tracker app.
/// Dark-first design with glassmorphism-friendly colors.
class AppColors {
  AppColors._();

  // ──────────────────────────────────────────────
  // Dark Theme Colors (Primary)
  // ──────────────────────────────────────────────

  /// Deep navy scaffold background
  static const Color scaffoldDark = Color(0xFF0A0E21);

  /// Slightly lighter navy for cards
  static const Color cardDark = Color(0xFF1A1F38);

  /// Surface color for elevated elements
  static const Color surfaceDark = Color(0xFF252A42);

  /// Subtle border color for dark theme
  static const Color border = Color(0xFF2D3250);

  /// Glass overlay color for glassmorphism effect
  static const Color glassOverlay = Color(0x1AFFFFFF);

  // ──────────────────────────────────────────────
  // Primary Gradient (Teal → Purple)
  // ──────────────────────────────────────────────

  /// Primary teal accent
  static const Color primaryTeal = Color(0xFF00D2FF);

  /// Primary purple accent
  static const Color primaryPurple = Color(0xFF7A5CFF);

  /// Main gradient used across the app
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Horizontal variant of the primary gradient
  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    colors: [primaryTeal, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ──────────────────────────────────────────────
  // Semantic Colors
  // ──────────────────────────────────────────────

  /// Income green
  static const Color income = Color(0xFF00E676);

  /// Expense coral red
  static const Color expense = Color(0xFFFF5252);

  /// Warning amber
  static const Color warning = Color(0xFFFFAB40);

  /// Info blue
  static const Color info = Color(0xFF448AFF);

  /// Success green (distinct from income)
  static const Color success = Color(0xFF69F0AE);

  // ──────────────────────────────────────────────
  // Text Colors (Dark Theme)
  // ──────────────────────────────────────────────

  /// Primary white text
  static const Color textPrimary = Colors.white;

  /// Secondary muted text
  static const Color textSecondary = Color(0xFF8E92A4);

  /// Disabled / hint text
  static const Color textHint = Color(0xFF5A5E72);

  // ──────────────────────────────────────────────
  // Category Colors (for expense/income categories)
  // ──────────────────────────────────────────────

  static const List<Color> categoryColors = [
    Color(0xFF00D2FF), // Teal
    Color(0xFF7A5CFF), // Purple
    Color(0xFFFF5252), // Red
    Color(0xFF00E676), // Green
    Color(0xFFFFAB40), // Amber
    Color(0xFFFF6EC7), // Pink
    Color(0xFF448AFF), // Blue
    Color(0xFFFF9100), // Orange
    Color(0xFFE040FB), // Magenta
    Color(0xFF76FF03), // Lime
    Color(0xFF18FFFF), // Cyan
    Color(0xFFFFEA00), // Yellow
  ];

  // ──────────────────────────────────────────────
  // Light Theme Colors
  // ──────────────────────────────────────────────

  /// Light scaffold background
  static const Color scaffoldLight = Color(0xFFF5F6FA);

  /// Light card background
  static const Color cardLight = Colors.white;

  /// Light surface color
  static const Color surfaceLight = Color(0xFFEEF0F5);

  /// Light border color
  static const Color borderLight = Color(0xFFE0E3EB);

  /// Light theme primary text
  static const Color textPrimaryLight = Color(0xFF1A1F38);

  /// Light theme secondary text
  static const Color textSecondaryLight = Color(0xFF6B7088);

  /// Light theme hint text
  static const Color textHintLight = Color(0xFF9DA2B5);

  // ──────────────────────────────────────────────
  // Chart Colors
  // ──────────────────────────────────────────────

  static const List<Color> chartColors = [
    Color(0xFF00D2FF),
    Color(0xFF7A5CFF),
    Color(0xFFFF5252),
    Color(0xFF00E676),
    Color(0xFFFFAB40),
    Color(0xFFFF6EC7),
    Color(0xFF448AFF),
    Color(0xFFFF9100),
  ];

  // ──────────────────────────────────────────────
  // Helper Methods
  // ──────────────────────────────────────────────

  /// Returns income or expense color based on transaction type
  static Color transactionColor(bool isIncome) {
    return isIncome ? income : expense;
  }

  /// Returns a shimmer gradient for loading states
  static LinearGradient get shimmerGradient => const LinearGradient(
        colors: [
          Color(0xFF1A1F38),
          Color(0xFF252A42),
          Color(0xFF1A1F38),
        ],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment(-1.0, -0.3),
        end: Alignment(1.0, 0.3),
      );
}
