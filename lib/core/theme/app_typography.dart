import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography using Google Fonts (Inter).
abstract class AppTypography {
  static const String fontFamily = 'Inter';

  /// Light Theme Text Hierarchy
  static TextTheme get lightTextTheme {
    return _buildTextTheme(
      primaryColor: AppColors.textPrimaryLight,
      secondaryColor: AppColors.textSecondaryLight,
      mutedColor: AppColors.textMutedLight,
    );
  }

  /// Dark Theme Text Hierarchy
  static TextTheme get darkTextTheme {
    return _buildTextTheme(
      primaryColor: AppColors.textPrimaryDark,
      secondaryColor: AppColors.textSecondaryDark,
      mutedColor: AppColors.textMutedDark,
    );
  }

  static TextTheme _buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      // Display: Hero numbers / Big Banner values
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: primaryColor,
      ),

      // Headlines: Screen headers / Section titles
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),

      // Titles: Card headers / Modal titles
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),

      // Body: General content / Descriptions / Form labels
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),

      // Labels: Buttons / Badges / Chips
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: mutedColor,
      ),
    );
  }

  /// Financial Amount Display Styles
  static TextStyle amountLarge({required bool isDark, Color? color}) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  static TextStyle amountMedium({required bool isDark, Color? color}) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  static TextStyle amountSmall({required bool isDark, Color? color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }
}
