import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';

/// Custom text styles for consistent typography.
/// Uses Outfit for display/headings and Inter for body text.
class AppTextStyles {
  AppTextStyles._();

  // ──────────────────────────────────────────────
  // Headings (Outfit font)
  // ──────────────────────────────────────────────

  /// 32px, bold — Hero sections, large balances
  static TextStyle heading1({Color? color}) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// 24px, semibold — Page titles
  static TextStyle heading2({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// 20px, semibold — Section titles
  static TextStyle heading3({Color? color}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// 18px, semibold — Card titles, sub-sections
  static TextStyle heading4({Color? color}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  // ──────────────────────────────────────────────
  // Body Text (Inter font)
  // ──────────────────────────────────────────────

  /// 16px, regular — Primary body text
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// 14px, regular — Default body text
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// 12px, regular — Secondary text, timestamps
  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  // ──────────────────────────────────────────────
  // Caption & Labels
  // ──────────────────────────────────────────────

  /// 11px, medium — Captions, small labels
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  /// 10px, semibold — Overline text, category labels
  static TextStyle overline({Color? color}) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 1.2,
      );

  // ──────────────────────────────────────────────
  // Button Styles
  // ──────────────────────────────────────────────

  /// 16px, semibold — Primary buttons
  static TextStyle button({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  /// 14px, semibold — Secondary/small buttons
  static TextStyle buttonSmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  // ──────────────────────────────────────────────
  // Specialized Styles
  // ──────────────────────────────────────────────

  /// Large amount display — 36px, bold
  static TextStyle amountLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  /// Medium amount display — 24px, bold
  static TextStyle amountMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// Small amount display — 16px, semibold
  static TextStyle amountSmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Input text style — 16px, regular
  static TextStyle input({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// Hint text style — 16px, regular, muted
  static TextStyle hint({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textHint,
      );

  /// Navigation label — 12px, medium
  static TextStyle navLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textSecondary,
      );

  /// Badge / chip text — 12px, semibold
  static TextStyle badge({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );
}
