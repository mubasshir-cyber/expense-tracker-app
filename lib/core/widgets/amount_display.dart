import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AmountSize {
  small,
  medium,
  large,
}

/// Centralized widget to display financial amounts formatted with currency and sign.
class AmountDisplay extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final bool? isCredit;
  final bool? isExpense;
  final bool showSign;
  final AmountSize size;
  final TextStyle? customStyle;
  final Color? customColor;
  final int decimalDigits;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.currencySymbol = '₹',
    this.isCredit,
    this.isExpense,
    this.showSign = false,
    this.size = AmountSize.medium,
    this.customStyle,
    this.customColor,
    this.decimalDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine semantic color
    Color effectiveColor;
    if (customColor != null) {
      effectiveColor = customColor!;
    } else if (isCredit == true) {
      effectiveColor = isDark ? const Color(0xFF34D399) : AppColors.credit;
    } else if (isExpense == true) {
      effectiveColor = isDark ? const Color(0xFFF87171) : AppColors.expense;
    } else {
      effectiveColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    // Determine typography style
    TextStyle style;
    if (customStyle != null) {
      style = customStyle!.copyWith(color: effectiveColor);
    } else {
      switch (size) {
        case AmountSize.large:
          style = AppTypography.amountLarge(isDark: isDark, color: effectiveColor);
          break;
        case AmountSize.medium:
          style = AppTypography.amountMedium(isDark: isDark, color: effectiveColor);
          break;
        case AmountSize.small:
          style = AppTypography.amountSmall(isDark: isDark, color: effectiveColor);
          break;
      }
    }

    // Format amount with commas (Indian / standard grouping)
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
      locale: 'en_IN',
    );
    final formattedNumber = formatter.format(amount.abs()).trim();

    // Determine sign prefix
    String signPrefix = '';
    if (showSign) {
      if (isCredit == true || amount > 0 && isExpense != true) {
        signPrefix = '+ ';
      } else if (isExpense == true || amount < 0) {
        signPrefix = '- ';
      }
    }

    final displayText = '$signPrefix$currencySymbol $formattedNumber';

    return Text(
      displayText,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
