import 'package:flutter/foundation.dart';
import 'dashboard_widget_type.dart';

@immutable
class DashboardWidgetConfig {
  const DashboardWidgetConfig({
    required this.type,
    this.isVisible = true,
  });

  final DashboardWidgetType type;
  final bool isVisible;

  DashboardWidgetConfig copyWith({
    DashboardWidgetType? type,
    bool? isVisible,
  }) {
    return DashboardWidgetConfig(
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.key,
      'isVisible': isVisible,
    };
  }

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = DashboardWidgetType.fromKey(typeStr);
    if (type == null) {
      throw ArgumentError('Unknown dashboard widget type: $typeStr');
    }
    // Support both 'isVisible' and 'visible' keys
    final visible = (json['isVisible'] ?? json['visible'] ?? true) as bool;
    return DashboardWidgetConfig(
      type: type,
      isVisible: visible,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardWidgetConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          isVisible == other.isVisible;

  @override
  int get hashCode => type.hashCode ^ isVisible.hashCode;

  @override
  String toString() => 'DashboardWidgetConfig(type: ${type.name}, isVisible: $isVisible)';
}

@immutable
class DashboardLayout {
  const DashboardLayout({
    this.version = currentVersion,
    required this.widgets,
  });

  static const int currentVersion = 1;

  final int version;
  final List<DashboardWidgetConfig> widgets;

  /// Default focused layout for daily financial activity:
  /// Primary Visible:
  /// 1. Balance
  /// 2. Monthly Summary
  /// 3. Quick Actions
  /// 4. Recent Transactions
  /// Secondary Configurable (accessible via Side Drawer & customizable):
  /// 5. Budgets
  /// 6. Recurring
  /// 7. Savings Goals
  /// 8. Debts
  static DashboardLayout defaultLayout() {
    return const DashboardLayout(
      version: currentVersion,
      widgets: [
        DashboardWidgetConfig(type: DashboardWidgetType.balance, isVisible: true),
        DashboardWidgetConfig(type: DashboardWidgetType.monthlySummary, isVisible: true),
        DashboardWidgetConfig(type: DashboardWidgetType.quickActions, isVisible: true),
        DashboardWidgetConfig(type: DashboardWidgetType.recentTransactions, isVisible: true),
        DashboardWidgetConfig(type: DashboardWidgetType.budgets, isVisible: false),
        DashboardWidgetConfig(type: DashboardWidgetType.recurring, isVisible: false),
        DashboardWidgetConfig(type: DashboardWidgetType.savingsGoals, isVisible: false),
        DashboardWidgetConfig(type: DashboardWidgetType.debts, isVisible: false),
      ],
    );
  }

  /// List of widgets that are currently marked as visible.
  List<DashboardWidgetConfig> get visibleWidgets =>
      widgets.where((w) => w.isVisible).toList();

  /// Whether all widgets in the layout are currently hidden.
  bool get isEmpty => visibleWidgets.isEmpty;

  DashboardLayout copyWith({
    int? version,
    List<DashboardWidgetConfig>? widgets,
  }) {
    return DashboardLayout(
      version: version ?? this.version,
      widgets: widgets ?? this.widgets,
    );
  }

  /// Reorders widgets in the layout.
  /// Handles standard Flutter ReorderableListView indexing where
  /// newIndex is shifted if oldIndex < newIndex.
  DashboardLayout reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= widgets.length) return this;
    var effectiveNewIndex = newIndex;
    if (oldIndex < effectiveNewIndex) {
      effectiveNewIndex -= 1;
    }
    if (effectiveNewIndex < 0) effectiveNewIndex = 0;
    if (effectiveNewIndex >= widgets.length) effectiveNewIndex = widgets.length - 1;

    final updated = List<DashboardWidgetConfig>.from(widgets);
    final item = updated.removeAt(oldIndex);
    updated.insert(effectiveNewIndex, item);

    return copyWith(widgets: List.unmodifiable(updated));
  }

  /// Toggles visibility for a specific widget type.
  DashboardLayout toggleVisibility(DashboardWidgetType type, bool isVisible) {
    final updated = widgets.map((config) {
      if (config.type == type) {
        return config.copyWith(isVisible: isVisible);
      }
      return config;
    }).toList();

    return copyWith(widgets: List.unmodifiable(updated));
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'widgets': widgets.map((w) => w.toJson()).toList(),
    };
  }

  /// Deserializes a layout from JSON with schema migration and fallback.
  /// - Automatically ignores unknown widget types.
  /// - Automatically appends any new widget types that might not be in the stored config.
  /// - Falls back to defaultLayout() on parsing failure or empty result.
  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    try {
      final parsedVersion = json['version'] as int? ?? currentVersion;
      final rawWidgets = json['widgets'];

      if (rawWidgets is! List) {
        return DashboardLayout.defaultLayout();
      }

      final parsedList = <DashboardWidgetConfig>[];
      final seenTypes = <DashboardWidgetType>{};

      for (final raw in rawWidgets) {
        if (raw is Map<String, dynamic>) {
          try {
            final config = DashboardWidgetConfig.fromJson(raw);
            if (!seenTypes.contains(config.type)) {
              seenTypes.add(config.type);
              parsedList.add(config);
            }
          } catch (_) {
            // Ignore unknown or corrupted widget entries
          }
        }
      }

      // Automatically migrate / append any newly added widget types
      for (final defaultType in DashboardLayout.defaultLayout().widgets) {
        if (!seenTypes.contains(defaultType.type)) {
          parsedList.add(defaultType);
          seenTypes.add(defaultType.type);
        }
      }

      if (parsedList.isEmpty) {
        return DashboardLayout.defaultLayout();
      }

      return DashboardLayout(
        version: parsedVersion,
        widgets: List.unmodifiable(parsedList),
      );
    } catch (_) {
      return DashboardLayout.defaultLayout();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayout &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          listEquals(widgets, other.widgets);

  @override
  int get hashCode => version.hashCode ^ widgets.hashCode;

  @override
  String toString() => 'DashboardLayout(version: $version, widgets: $widgets)';
}
