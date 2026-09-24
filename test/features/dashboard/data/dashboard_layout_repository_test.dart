import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/features/dashboard/data/repositories/dashboard_layout_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_layout.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_widget_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesDashboardLayoutRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadLayout returns defaultLayout when storage is empty', () async {
      final repo = SharedPreferencesDashboardLayoutRepository();
      final layout = await repo.loadLayout();
      expect(layout, DashboardLayout.defaultLayout());
    });

    test('saveLayout persists layout JSON and loadLayout restores it correctly', () async {
      final repo = SharedPreferencesDashboardLayoutRepository();
      var customLayout = DashboardLayout.defaultLayout();
      customLayout = customLayout.reorder(0, 5);
      customLayout = customLayout.toggleVisibility(DashboardWidgetType.debts, false);

      await repo.saveLayout(customLayout);

      final loaded = await repo.loadLayout();
      expect(loaded.widgets.length, 8);
      expect(loaded.widgets[0].type, customLayout.widgets[0].type);
      expect(
        loaded.widgets.firstWhere((w) => w.type == DashboardWidgetType.debts).isVisible,
        isFalse,
      );
    });

    test('resetLayout restores default layout in storage', () async {
      final repo = SharedPreferencesDashboardLayoutRepository();
      var customLayout = DashboardLayout.defaultLayout();
      customLayout = customLayout.toggleVisibility(DashboardWidgetType.balance, false);
      await repo.saveLayout(customLayout);

      final saved = await repo.loadLayout();
      expect(saved.widgets.firstWhere((w) => w.type == DashboardWidgetType.balance).isVisible, isFalse);

      await repo.resetLayout();
      final reset = await repo.loadLayout();
      expect(reset, DashboardLayout.defaultLayout());
    });

    test('loadLayout returns defaultLayout when storage contains corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesDashboardLayoutRepository.storageKey: '{corrupted_not_json',
      });
      final repo = SharedPreferencesDashboardLayoutRepository();
      final layout = await repo.loadLayout();
      expect(layout, DashboardLayout.defaultLayout());
    });

    test('loadLayout handles non-map json gracefully', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesDashboardLayoutRepository.storageKey: jsonEncode(['a', 'b']),
      });
      final repo = SharedPreferencesDashboardLayoutRepository();
      final layout = await repo.loadLayout();
      expect(layout, DashboardLayout.defaultLayout());
    });
  });
}
