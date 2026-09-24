import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_layout.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_widget_type.dart';

void main() {
  group('DashboardWidgetType', () {
    test('fromKey returns correct type for key or name', () {
      expect(DashboardWidgetType.fromKey('balance'), DashboardWidgetType.balance);
      expect(DashboardWidgetType.fromKey('monthlySummary'), DashboardWidgetType.monthlySummary);
      expect(DashboardWidgetType.fromKey('quickActions'), DashboardWidgetType.quickActions);
      expect(DashboardWidgetType.fromKey('budgets'), DashboardWidgetType.budgets);
      expect(DashboardWidgetType.fromKey('recurring'), DashboardWidgetType.recurring);
      expect(DashboardWidgetType.fromKey('savingsGoals'), DashboardWidgetType.savingsGoals);
      expect(DashboardWidgetType.fromKey('debts'), DashboardWidgetType.debts);
      expect(DashboardWidgetType.fromKey('recentTransactions'), DashboardWidgetType.recentTransactions);
      expect(DashboardWidgetType.fromKey('unknownWidgetType'), isNull);
      expect(DashboardWidgetType.fromKey(null), isNull);
    });

    test('each widget type has valid display metadata', () {
      for (final type in DashboardWidgetType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.description.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
      }
    });
  });

  group('DashboardWidgetConfig', () {
    test('instantiates with defaults and supports copyWith', () {
      const config = DashboardWidgetConfig(type: DashboardWidgetType.balance);
      expect(config.type, DashboardWidgetType.balance);
      expect(config.isVisible, isTrue);

      final hidden = config.copyWith(isVisible: false);
      expect(hidden.isVisible, isFalse);
      expect(hidden.type, DashboardWidgetType.balance);
    });

    test('toJson and fromJson work correctly with isVisible and visible keys', () {
      const config = DashboardWidgetConfig(
        type: DashboardWidgetType.budgets,
        isVisible: false,
      );
      final json = config.toJson();
      expect(json['type'], 'budgets');
      expect(json['isVisible'], isFalse);

      final fromJson = DashboardWidgetConfig.fromJson(json);
      expect(fromJson, config);

      final fromAltJson = DashboardWidgetConfig.fromJson({
        'type': 'debts',
        'visible': false,
      });
      expect(fromAltJson.type, DashboardWidgetType.debts);
      expect(fromAltJson.isVisible, isFalse);
    });

    test('fromJson throws ArgumentError for unknown type', () {
      expect(
        () => DashboardWidgetConfig.fromJson({'type': 'invalid_type'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('DashboardLayout', () {
    test('defaultLayout returns all 8 widgets in exact default specification order', () {
      final layout = DashboardLayout.defaultLayout();
      expect(layout.version, 1);
      expect(layout.widgets.length, 8);
      
      // Top 4 widgets are visible by default
      expect(layout.visibleWidgets.length, 4);

      expect(layout.widgets[0].type, DashboardWidgetType.balance);
      expect(layout.widgets[0].isVisible, isTrue);

      expect(layout.widgets[1].type, DashboardWidgetType.monthlySummary);
      expect(layout.widgets[1].isVisible, isTrue);

      expect(layout.widgets[2].type, DashboardWidgetType.quickActions);
      expect(layout.widgets[2].isVisible, isTrue);

      expect(layout.widgets[3].type, DashboardWidgetType.recentTransactions);
      expect(layout.widgets[3].isVisible, isTrue);

      expect(layout.widgets[4].type, DashboardWidgetType.budgets);
      expect(layout.widgets[4].isVisible, isFalse);

      expect(layout.widgets[5].type, DashboardWidgetType.recurring);
      expect(layout.widgets[5].isVisible, isFalse);

      expect(layout.widgets[6].type, DashboardWidgetType.savingsGoals);
      expect(layout.widgets[6].isVisible, isFalse);

      expect(layout.widgets[7].type, DashboardWidgetType.debts);
      expect(layout.widgets[7].isVisible, isFalse);
    });

    test('visibleWidgets returns only widgets where isVisible is true', () {
      var layout = DashboardLayout.defaultLayout();
      expect(layout.visibleWidgets.length, 4);

      layout = layout.toggleVisibility(DashboardWidgetType.budgets, true);
      layout = layout.toggleVisibility(DashboardWidgetType.debts, true);

      expect(layout.visibleWidgets.length, 6);
      expect(
        layout.visibleWidgets.map((w) => w.type),
        contains(DashboardWidgetType.budgets),
      );
      expect(
        layout.visibleWidgets.map((w) => w.type),
        contains(DashboardWidgetType.debts),
      );
    });

    test('isEmpty returns true when all widgets are hidden', () {
      var layout = DashboardLayout.defaultLayout();
      expect(layout.isEmpty, isFalse);

      for (final widget in layout.widgets) {
        layout = layout.toggleVisibility(widget.type, false);
      }
      expect(layout.isEmpty, isTrue);
      expect(layout.visibleWidgets, isEmpty);
    });

    test('reorder moves first item to last position', () {
      final layout = DashboardLayout.defaultLayout();
      // Reorder item 0 to after item 7 (newIndex = 8 in ReorderableListView conventions)
      final reordered = layout.reorder(0, 8);
      expect(reordered.widgets.last.type, DashboardWidgetType.balance);
      expect(reordered.widgets.first.type, DashboardWidgetType.monthlySummary);
      expect(reordered.widgets.length, 8);
    });

    test('reorder moves last item to first position', () {
      final layout = DashboardLayout.defaultLayout();
      // Reorder item 7 to index 0
      final reordered = layout.reorder(7, 0);
      expect(reordered.widgets.first.type, DashboardWidgetType.debts);
      expect(reordered.widgets[1].type, DashboardWidgetType.balance);
      expect(reordered.widgets.length, 8);
    });

    test('reorder handles invalid indices gracefully', () {
      final layout = DashboardLayout.defaultLayout();
      expect(layout.reorder(-1, 2), layout);
      expect(layout.reorder(10, 2), layout);
    });

    test('toggleVisibility toggles ON and OFF twice', () {
      var layout = DashboardLayout.defaultLayout();
      expect(layout.widgets.firstWhere((w) => w.type == DashboardWidgetType.recurring).isVisible, isFalse);

      layout = layout.toggleVisibility(DashboardWidgetType.recurring, true);
      expect(layout.widgets.firstWhere((w) => w.type == DashboardWidgetType.recurring).isVisible, isTrue);

      layout = layout.toggleVisibility(DashboardWidgetType.recurring, false);
      expect(layout.widgets.firstWhere((w) => w.type == DashboardWidgetType.recurring).isVisible, isFalse);
    });

    test('toJson and fromJson correctly round-trip', () {
      var layout = DashboardLayout.defaultLayout();
      layout = layout.reorder(0, 3);
      layout = layout.toggleVisibility(DashboardWidgetType.quickActions, false);

      final json = layout.toJson();
      expect(json['version'], 1);
      expect(json['widgets'], isA<List>());

      final deserialized = DashboardLayout.fromJson(json);
      expect(deserialized.widgets.length, 8);
      expect(deserialized.widgets[0].type, layout.widgets[0].type);
      expect(deserialized.widgets[1].type, layout.widgets[1].type);
      expect(
        deserialized.widgets.firstWhere((w) => w.type == DashboardWidgetType.quickActions).isVisible,
        isFalse,
      );
    });

    test('fromJson auto-migrates missing new widgets with default visibility', () {
      // Simulating an older saved layout missing savingsGoals and debts
      final oldJson = {
        'version': 1,
        'widgets': [
          {'type': 'balance', 'isVisible': true},
          {'type': 'monthlySummary', 'isVisible': true},
          {'type': 'quickActions', 'isVisible': false},
          {'type': 'budgets', 'isVisible': true},
          {'type': 'recurring', 'isVisible': true},
          {'type': 'recentTransactions', 'isVisible': true},
        ],
      };

      final migrated = DashboardLayout.fromJson(oldJson);
      expect(migrated.widgets.length, 8);
      expect(
        migrated.widgets.firstWhere((w) => w.type == DashboardWidgetType.quickActions).isVisible,
        isFalse,
      );
      // New widgets were added automatically from default layout definitions
      expect(
        migrated.widgets.firstWhere((w) => w.type == DashboardWidgetType.savingsGoals).isVisible,
        isFalse,
      );
      expect(
        migrated.widgets.firstWhere((w) => w.type == DashboardWidgetType.debts).isVisible,
        isFalse,
      );
    });

    test('fromJson ignores unknown widget types gracefully', () {
      final jsonWithUnknown = {
        'version': 1,
        'widgets': [
          {'type': 'non_existent_future_widget', 'isVisible': true},
          {'type': 'balance', 'isVisible': false},
          {'type': 'monthlySummary', 'isVisible': true},
        ],
      };

      final result = DashboardLayout.fromJson(jsonWithUnknown);
      expect(result.widgets.length, 8);
      expect(
        result.widgets.firstWhere((w) => w.type == DashboardWidgetType.balance).isVisible,
        isFalse,
      );
    });

    test('fromJson falls back safely on corrupted data', () {
      expect(DashboardLayout.fromJson({}), DashboardLayout.defaultLayout());
      expect(DashboardLayout.fromJson({'widgets': 'not-a-list'}), DashboardLayout.defaultLayout());
      expect(DashboardLayout.fromJson({'widgets': []}), DashboardLayout.defaultLayout());
    });
  });
}
