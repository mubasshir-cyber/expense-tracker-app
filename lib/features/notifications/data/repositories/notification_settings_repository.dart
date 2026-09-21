import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notification_settings_model.dart';

class NotificationSettingsRepository {
  NotificationSettingsRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user.id;
  }

  /// Fetches the user's notification preferences, or creates default settings if not yet saved.
  Future<NotificationSettingsModel> getSettings() async {
    final response = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) {
      final defaultModel = NotificationSettingsModel.defaultSettings(_userId);
      await saveSettings(defaultModel);
      return defaultModel;
    }

    return NotificationSettingsModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Upserts notification preferences for the user.
  Future<NotificationSettingsModel> saveSettings(
    NotificationSettingsModel settings,
  ) async {
    final payload = {
      'user_id': _userId,
      'budget_warning_enabled': settings.budgetWarningEnabled,
      'budget_exceeded_enabled': settings.budgetExceededEnabled,
      'recurring_upcoming_enabled': settings.recurringUpcomingEnabled,
      'recurring_auto_created_enabled': settings.recurringAutoCreatedEnabled,
      'spending_alerts_enabled': settings.spendingAlertsEnabled,
      'monthly_summary_enabled': settings.monthlySummaryEnabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('notification_settings')
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();

    return NotificationSettingsModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}
