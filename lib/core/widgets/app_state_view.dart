import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Enum representing standardized application states for screens and data views.
enum AppStateType {
  loading,
  empty,
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  maintenance,
  updateRequired,
  genericError,
  success,
}

/// A production-grade, highly polished reusable state view for screens across the application.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.customIcon,
    this.iconColor,
  });

  final AppStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? customIcon;
  final Color? iconColor;

  /// Factory helper for Loading state
  const AppStateView.loading({
    super.key,
    this.title = 'Loading...',
    this.message,
  })  : type = AppStateType.loading,
        actionLabel = null,
        onAction = null,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = null,
        iconColor = null;

  /// Factory helper for Empty state
  const AppStateView.empty({
    super.key,
    this.title = 'No Data Found',
    this.message = 'There are no records to display at this time.',
    this.actionLabel,
    this.onAction,
    this.customIcon = LucideIcons.inbox,
    this.iconColor,
  })  : type = AppStateType.empty,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Factory helper for Offline / No Internet state
  const AppStateView.offline({
    super.key,
    this.title = 'No Internet Connection',
    this.message = 'Please check your Wi-Fi or mobile network and try again.',
    this.actionLabel = 'Retry',
    this.onAction,
  })  : type = AppStateType.noInternet,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.wifiOff,
        iconColor = AppColors.warning;

  /// Factory helper for Timeout state
  const AppStateView.timeout({
    super.key,
    this.title = 'Request Timed Out',
    this.message = 'The server took too long to respond. Please try again.',
    this.actionLabel = 'Retry',
    this.onAction,
  })  : type = AppStateType.timeout,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.timerReset,
        iconColor = AppColors.warning;

  /// Factory helper for 401 Unauthorized / Session Expired
  const AppStateView.unauthorized({
    super.key,
    this.title = 'Session Expired',
    this.message = 'Your session has expired. Please sign in again to continue.',
    this.actionLabel = 'Sign In',
    this.onAction,
  })  : type = AppStateType.unauthorized,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.shieldAlert,
        iconColor = AppColors.error;

  /// Factory helper for 403 Forbidden
  const AppStateView.forbidden({
    super.key,
    this.title = 'Access Denied',
    this.message = 'You do not have permission to access this resource.',
    this.actionLabel = 'Go Back',
    this.onAction,
  })  : type = AppStateType.forbidden,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.lock,
        iconColor = AppColors.error;

  /// Factory helper for 404 Not Found
  const AppStateView.notFound({
    super.key,
    this.title = 'Page Not Found',
    this.message = 'The requested item or screen could not be located.',
    this.actionLabel = 'Return Home',
    this.onAction,
  })  : type = AppStateType.notFound,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.fileSearch,
        iconColor = AppColors.primary;

  /// Factory helper for 500 Server Error
  const AppStateView.serverError({
    super.key,
    this.title = 'Server Error',
    this.message = 'Something went wrong on our end. Please try again later.',
    this.actionLabel = 'Retry',
    this.onAction,
  })  : type = AppStateType.serverError,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.serverCrash,
        iconColor = AppColors.error;

  /// Factory helper for Maintenance mode
  const AppStateView.maintenance({
    super.key,
    this.title = 'Under Maintenance',
    this.message = 'We are currently performing scheduled maintenance. Please check back shortly.',
    this.actionLabel = 'Check Status',
    this.onAction,
  })  : type = AppStateType.maintenance,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.wrench,
        iconColor = AppColors.primary;

  /// Factory helper for App Update Required
  const AppStateView.updateRequired({
    super.key,
    this.title = 'Update Required',
    this.message = 'A critical new version of Expense Tracker is available. Please update to continue.',
    this.actionLabel = 'Update App',
    this.onAction,
  })  : type = AppStateType.updateRequired,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.arrowUpCircle,
        iconColor = AppColors.primary;

  /// Factory helper for Generic Error
  const AppStateView.error({
    super.key,
    this.title = 'Something Went Wrong',
    this.message = 'An unexpected error occurred. Please try again.',
    this.actionLabel = 'Retry',
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  })  : type = AppStateType.genericError,
        customIcon = LucideIcons.alertTriangle,
        iconColor = AppColors.error;

  /// Factory helper for Success state
  const AppStateView.success({
    super.key,
    this.title = 'Success!',
    this.message = 'The operation completed successfully.',
    this.actionLabel = 'Continue',
    this.onAction,
  })  : type = AppStateType.success,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        customIcon = LucideIcons.checkCircle2,
        iconColor = AppColors.credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (type == AppStateType.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                title ?? 'Loading...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final effectiveIcon = customIcon ?? _getDefaultIcon(type);
    final effectiveIconColor = iconColor ?? _getDefaultIconColor(type);
    final effectiveTitle = title ?? _getDefaultTitle(type);
    final effectiveMessage = message ?? _getDefaultMessage(type);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveIconColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  effectiveIcon,
                  size: 40,
                  color: effectiveIconColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                effectiveTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (effectiveMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  effectiveMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    type: _getButtonType(type),
                  ),
                ),
              ],
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDefaultIcon(AppStateType type) {
    switch (type) {
      case AppStateType.loading:
        return LucideIcons.loader2;
      case AppStateType.empty:
        return LucideIcons.inbox;
      case AppStateType.noInternet:
        return LucideIcons.wifiOff;
      case AppStateType.timeout:
        return LucideIcons.timerReset;
      case AppStateType.unauthorized:
        return LucideIcons.shieldAlert;
      case AppStateType.forbidden:
        return LucideIcons.lock;
      case AppStateType.notFound:
        return LucideIcons.fileSearch;
      case AppStateType.serverError:
        return LucideIcons.serverCrash;
      case AppStateType.maintenance:
        return LucideIcons.wrench;
      case AppStateType.updateRequired:
        return LucideIcons.arrowUpCircle;
      case AppStateType.genericError:
        return LucideIcons.alertTriangle;
      case AppStateType.success:
        return LucideIcons.checkCircle2;
    }
  }

  Color _getDefaultIconColor(AppStateType type) {
    switch (type) {
      case AppStateType.loading:
      case AppStateType.empty:
      case AppStateType.notFound:
      case AppStateType.maintenance:
      case AppStateType.updateRequired:
        return AppColors.primary;
      case AppStateType.noInternet:
      case AppStateType.timeout:
        return AppColors.warning;
      case AppStateType.unauthorized:
      case AppStateType.forbidden:
      case AppStateType.serverError:
      case AppStateType.genericError:
        return AppColors.error;
      case AppStateType.success:
        return AppColors.credit;
    }
  }

  String _getDefaultTitle(AppStateType type) {
    switch (type) {
      case AppStateType.loading:
        return 'Loading...';
      case AppStateType.empty:
        return 'No Items Found';
      case AppStateType.noInternet:
        return 'No Internet Connection';
      case AppStateType.timeout:
        return 'Connection Timed Out';
      case AppStateType.unauthorized:
        return 'Session Expired';
      case AppStateType.forbidden:
        return 'Access Forbidden';
      case AppStateType.notFound:
        return 'Resource Not Found';
      case AppStateType.serverError:
        return 'Internal Server Error';
      case AppStateType.maintenance:
        return 'System Maintenance';
      case AppStateType.updateRequired:
        return 'App Update Required';
      case AppStateType.genericError:
        return 'Something Went Wrong';
      case AppStateType.success:
        return 'Completed Successfully';
    }
  }

  String _getDefaultMessage(AppStateType type) {
    switch (type) {
      case AppStateType.loading:
        return '';
      case AppStateType.empty:
        return 'There is nothing to display here yet.';
      case AppStateType.noInternet:
        return 'Please check your connection and try again.';
      case AppStateType.timeout:
        return 'The request took too long. Please try again.';
      case AppStateType.unauthorized:
        return 'Please sign in again to access your account.';
      case AppStateType.forbidden:
        return 'You do not have permission to view this content.';
      case AppStateType.notFound:
        return 'The item you are looking for does not exist.';
      case AppStateType.serverError:
        return 'Our servers encountered an error. Please try again later.';
      case AppStateType.maintenance:
        return 'Expense Tracker is currently undergoing maintenance. Please check back soon.';
      case AppStateType.updateRequired:
        return 'Please update to the latest version to continue using the application.';
      case AppStateType.genericError:
        return 'An error occurred while processing your request.';
      case AppStateType.success:
        return 'Your action has been recorded successfully.';
    }
  }

  AppButtonType _getButtonType(AppStateType type) {
    switch (type) {
      case AppStateType.unauthorized:
      case AppStateType.forbidden:
      case AppStateType.serverError:
      case AppStateType.genericError:
        return AppButtonType.primary;
      default:
        return AppButtonType.primary;
    }
  }
}
