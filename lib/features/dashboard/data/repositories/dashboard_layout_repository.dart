import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/dashboard_layout.dart';

abstract class DashboardLayoutRepository {
  Future<DashboardLayout> loadLayout();
  Future<void> saveLayout(DashboardLayout layout);
  Future<void> resetLayout();
}

class SharedPreferencesDashboardLayoutRepository implements DashboardLayoutRepository {
  SharedPreferencesDashboardLayoutRepository({this.preferences});

  static const String storageKey = 'dashboard_layout_config';

  final SharedPreferences? preferences;

  Future<SharedPreferences> _getPrefs() async {
    return preferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<DashboardLayout> loadLayout() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return DashboardLayout.defaultLayout();
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return DashboardLayout.fromJson(decoded);
      }
      return DashboardLayout.defaultLayout();
    } catch (_) {
      return DashboardLayout.defaultLayout();
    }
  }

  @override
  Future<void> saveLayout(DashboardLayout layout) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(layout.toJson());
      await prefs.setString(storageKey, jsonString);
    } catch (_) {
      // Gracefully handle storage errors
    }
  }

  @override
  Future<void> resetLayout() async {
    final defaultLayout = DashboardLayout.defaultLayout();
    await saveLayout(defaultLayout);
  }
}
