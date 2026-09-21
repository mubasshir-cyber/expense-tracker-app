/// User preferences for smart financial notification channels.
class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.userId,
    this.budgetWarningEnabled = true,
    this.budgetExceededEnabled = true,
    this.recurringUpcomingEnabled = true,
    this.recurringAutoCreatedEnabled = true,
    this.spendingAlertsEnabled = true,
    this.monthlySummaryEnabled = true,
  });

  final String userId;
  final bool budgetWarningEnabled;
  final bool budgetExceededEnabled;
  final bool recurringUpcomingEnabled;
  final bool recurringAutoCreatedEnabled;
  final bool spendingAlertsEnabled;
  final bool monthlySummaryEnabled;

  factory NotificationSettingsModel.defaultSettings(String userId) {
    return NotificationSettingsModel(userId: userId);
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      userId: map['user_id'] as String,
      budgetWarningEnabled: map['budget_warning_enabled'] as bool? ?? true,
      budgetExceededEnabled: map['budget_exceeded_enabled'] as bool? ?? true,
      recurringUpcomingEnabled:
          map['recurring_upcoming_enabled'] as bool? ?? true,
      recurringAutoCreatedEnabled:
          map['recurring_auto_created_enabled'] as bool? ?? true,
      spendingAlertsEnabled: map['spending_alerts_enabled'] as bool? ?? true,
      monthlySummaryEnabled: map['monthly_summary_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'budget_warning_enabled': budgetWarningEnabled,
      'budget_exceeded_enabled': budgetExceededEnabled,
      'recurring_upcoming_enabled': recurringUpcomingEnabled,
      'recurring_auto_created_enabled': recurringAutoCreatedEnabled,
      'spending_alerts_enabled': spendingAlertsEnabled,
      'monthly_summary_enabled': monthlySummaryEnabled,
    };
  }

  NotificationSettingsModel copyWith({
    String? userId,
    bool? budgetWarningEnabled,
    bool? budgetExceededEnabled,
    bool? recurringUpcomingEnabled,
    bool? recurringAutoCreatedEnabled,
    bool? spendingAlertsEnabled,
    bool? monthlySummaryEnabled,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      budgetWarningEnabled: budgetWarningEnabled ?? this.budgetWarningEnabled,
      budgetExceededEnabled:
          budgetExceededEnabled ?? this.budgetExceededEnabled,
      recurringUpcomingEnabled:
          recurringUpcomingEnabled ?? this.recurringUpcomingEnabled,
      recurringAutoCreatedEnabled:
          recurringAutoCreatedEnabled ?? this.recurringAutoCreatedEnabled,
      spendingAlertsEnabled:
          spendingAlertsEnabled ?? this.spendingAlertsEnabled,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
    );
  }
}
