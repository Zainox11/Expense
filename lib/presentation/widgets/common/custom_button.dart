import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium gradient button with loading state support.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Gradient? gradient;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.textColor,
    this.borderColor,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = LinearGradient(
      colors: [const Color(0xFF00D2FF), const Color(0xFF7A5CFF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: borderColor ?? const Color(0xFF00D2FF),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildContent(isDark, isOutlined: true),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading
              ? (gradient ?? defaultGradient)
              : null,
          color: onPressed == null || isLoading
              ? (isDark ? const Color(0xFF2D3250) : Colors.grey[300])
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(child: _buildContent(isDark)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, {bool isOutlined = false}) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(
            isOutlined ? const Color(0xFF00D2FF) : Colors.white,
          ),
        ),
      );
    }

    final color = textColor ??
        (isOutlined ? const Color(0xFF00D2FF) : Colors.white);

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
