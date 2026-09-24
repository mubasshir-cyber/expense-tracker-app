import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences model for OS-level device notifications.
class SystemNotificationPreferences {
  const SystemNotificationPreferences({
    this.systemNotificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.recurringAlertsEnabled = true,
    this.loanAlertsEnabled = true,
    this.savingsAlertsEnabled = true,
    this.khataAlertsEnabled = true,
    this.hideSensitiveAmounts = false,
  });

  final bool systemNotificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool recurringAlertsEnabled;
  final bool loanAlertsEnabled;
  final bool savingsAlertsEnabled;
  final bool khataAlertsEnabled;
  final bool hideSensitiveAmounts;

  SystemNotificationPreferences copyWith({
    bool? systemNotificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? recurringAlertsEnabled,
    bool? loanAlertsEnabled,
    bool? savingsAlertsEnabled,
    bool? khataAlertsEnabled,
    bool? hideSensitiveAmounts,
  }) {
    return SystemNotificationPreferences(
      systemNotificationsEnabled:
          systemNotificationsEnabled ?? this.systemNotificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      recurringAlertsEnabled:
          recurringAlertsEnabled ?? this.recurringAlertsEnabled,
      loanAlertsEnabled: loanAlertsEnabled ?? this.loanAlertsEnabled,
      savingsAlertsEnabled: savingsAlertsEnabled ?? this.savingsAlertsEnabled,
      khataAlertsEnabled: khataAlertsEnabled ?? this.khataAlertsEnabled,
      hideSensitiveAmounts: hideSensitiveAmounts ?? this.hideSensitiveAmounts,
    );
  }
}

/// Repository for saving and loading local system notification preferences from SharedPreferences.
class SystemNotificationPreferencesRepository {
  static const _kSystemEnabled = 'sys_notif_enabled';
  static const _kBudgetEnabled = 'sys_notif_budget_enabled';
  static const _kRecurringEnabled = 'sys_notif_recurring_enabled';
  static const _kLoanEnabled = 'sys_notif_loan_enabled';
  static const _kSavingsEnabled = 'sys_notif_savings_enabled';
  static const _kKhataEnabled = 'sys_notif_khata_enabled';
  static const _kHideAmounts = 'sys_notif_hide_amounts';

  Future<SystemNotificationPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return SystemNotificationPreferences(
      systemNotificationsEnabled: prefs.getBool(_kSystemEnabled) ?? true,
      budgetAlertsEnabled: prefs.getBool(_kBudgetEnabled) ?? true,
      recurringAlertsEnabled: prefs.getBool(_kRecurringEnabled) ?? true,
      loanAlertsEnabled: prefs.getBool(_kLoanEnabled) ?? true,
      savingsAlertsEnabled: prefs.getBool(_kSavingsEnabled) ?? true,
      khataAlertsEnabled: prefs.getBool(_kKhataEnabled) ?? true,
      hideSensitiveAmounts: prefs.getBool(_kHideAmounts) ?? false,
    );
  }

  Future<void> savePreferences(SystemNotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSystemEnabled, preferences.systemNotificationsEnabled);
    await prefs.setBool(_kBudgetEnabled, preferences.budgetAlertsEnabled);
    await prefs.setBool(_kRecurringEnabled, preferences.recurringAlertsEnabled);
    await prefs.setBool(_kLoanEnabled, preferences.loanAlertsEnabled);
    await prefs.setBool(_kSavingsEnabled, preferences.savingsAlertsEnabled);
    await prefs.setBool(_kKhataEnabled, preferences.khataAlertsEnabled);
    await prefs.setBool(_kHideAmounts, preferences.hideSensitiveAmounts);
  }
}

final systemNotificationPreferencesRepoProvider =
    Provider<SystemNotificationPreferencesRepository>((ref) {
  return SystemNotificationPreferencesRepository();
});

final systemNotificationPreferencesProvider =
    AsyncNotifierProvider<SystemNotificationPreferencesNotifier,
        SystemNotificationPreferences>(
  SystemNotificationPreferencesNotifier.new,
);

class SystemNotificationPreferencesNotifier
    extends AsyncNotifier<SystemNotificationPreferences> {
  late final SystemNotificationPreferencesRepository _repo;

  @override
  Future<SystemNotificationPreferences> build() async {
    _repo = ref.read(systemNotificationPreferencesRepoProvider);
    return _repo.loadPreferences();
  }

  Future<void> updatePreferences(
      SystemNotificationPreferences newPreferences) async {
    state = AsyncData(newPreferences);
    await _repo.savePreferences(newPreferences);
  }
}
