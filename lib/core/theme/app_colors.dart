import 'package:flutter/material.dart';

/// Centralized color palette for the Personal Expense Tracker.
/// Never hardcode colors directly in widgets; always reference [AppColors].
abstract class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryContainerLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryContainerDark = Color(0xFF1E1B4B); // Indigo 950

  // Semantic Financial Colors
  static const Color credit = Color(0xFF10B981); // Emerald 500
  static const Color creditDark = Color(0xFF059669); // Emerald 600
  static const Color creditContainerLight = Color(0xFFECFDF5); // Emerald 50
  static const Color creditContainerDark = Color(0xFF064E3B); // Emerald 900

  static const Color expense = Color(0xFFEF4444); // Red 500
  static const Color expenseDark = Color(0xFFDC2626); // Red 600
  static const Color expenseContainerLight = Color(0xFFFEF2F2); // Red 50
  static const Color expenseContainerDark = Color(0xFF7F1D1D); // Red 900

  // Semantic Feedback
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainerLight = Color(0xFFFFFBEB);
  static const Color warningContainerDark = Color(0xFF78350F);

  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color success = credit;
  static const Color error = expense;

  // Light Theme Surfaces & Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderFocusLight = Color(0xFF94A3B8); // Slate 400

  // Dark Theme Surfaces & Backgrounds
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep dark slate
  static const Color surfaceDark = Color(0xFF111827); // Gray 900
  static const Color surfaceVariantDark = Color(0xFF1F2937); // Gray 800
  static const Color borderDark = Color(0xFF374151); // Gray 700
  static const Color borderFocusDark = Color(0xFF6B7280); // Gray 500

  // Typography Colors - Light Theme
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400
  static const Color textDisabledLight = Color(0xFFCBD5E1); // Slate 300

  // Typography Colors - Dark Theme
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500
  static const Color textDisabledDark = Color(0xFF475569); // Slate 600

  // Category Colors
  static const List<Color> categoryPalette = [
    Color(0xFF3B82F6), // Blue (Bills/Utilities)
    Color(0xFF10B981), // Green (Salary/Income)
    Color(0xFFF59E0B), // Amber (Food & Dining)
    Color(0xFFEC4899), // Pink (Shopping)
    Color(0xFF8B5CF6), // Purple (Entertainment)
    Color(0xFF06B6D4), // Cyan (Travel/Transport)
    Color(0xFF14B8A6), // Teal (Health/Medical)
    Color(0xFFF97316), // Orange (Education/Personal)
    Color(0xFF64748B), // Slate (Others)
  ];
}
