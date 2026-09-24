/// Global application release constants, support URLs, policy links and version controls.
abstract final class AppConfig {
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String fullVersionString = 'v$appVersion+$buildNumber';

  // Configurable URLs for Store compliance and user support
  static const String privacyPolicyUrl =
      'https://yourdomain.com/privacy-policy';
  static const String termsAndConditionsUrl =
      'https://yourdomain.com/terms-and-conditions';
  static const String accountDeletionUrl =
      'https://yourdomain.com/delete-account';
  static const String supportEmail = 'support@yourdomain.com';
  static const String appStoreUrl =
      'https://apps.apple.com/app/idYOUR_APP_ID';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.expense_tracker';

  // Minimum supported version enforcement
  static const String minimumSupportedVersion = '1.0.0';

  // Dynamic maintenance mode switch (can also be driven by remote config/backend)
  static const bool isMaintenanceMode = false;
}
