import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonType {
  primary,
  secondary,
  outlined,
  ghost,
}

/// Standard reusable button adhering to the design system.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonChild;
    if (isLoading) {
      final spinnerColor = (type == AppButtonType.outlined || type == AppButtonType.ghost)
          ? (customColor ?? theme.colorScheme.primary)
          : Colors.white;

      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      buttonChild = Text(label);
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (type) {
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonType.secondary:
        button = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: customColor ??
                (isDark
                    ? AppColors.primaryContainerDark
                    : AppColors.primaryContainerLight),
            foregroundColor: customColor != null
                ? Colors.white
                : (isDark ? AppColors.primaryLight : AppColors.primary),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight),
            side: BorderSide(
              color: customColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1,
            ),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonType.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? (isDark ? AppColors.primaryLight : AppColors.primary),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    return button;
  }
}
