import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/data/repositories/dashboard_layout_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_layout.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_widget_type.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/dashboard_layout_provider.dart';

class InMemoryDashboardLayoutRepository implements DashboardLayoutRepository {
  DashboardLayout currentLayout = DashboardLayout.defaultLayout();
  int saveCount = 0;
  int resetCount = 0;

  @override
  Future<DashboardLayout> loadLayout() async {
    return currentLayout;
  }

  @override
  Future<void> saveLayout(DashboardLayout layout) async {
    currentLayout = layout;
    saveCount++;
  }

  @override
  Future<void> resetLayout() async {
    currentLayout = DashboardLayout.defaultLayout();
    resetCount++;
  }
}

void main() {
  group('DashboardLayoutNotifier', () {
    late InMemoryDashboardLayoutRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = InMemoryDashboardLayoutRepository();
      container = ProviderContainer(
        overrides: [
          dashboardLayoutRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with default layout and triggers load', () async {
      final notifier = container.read(dashboardLayoutProvider.notifier);
      final layout = container.read(dashboardLayoutProvider);

      expect(layout.widgets.length, 8);
      expect(layout.widgets[0].type, DashboardWidgetType.balance);
      expect(notifier.state, layout);
    });

    test('reorder updates layout state and persists immediately', () async {
      final notifier = container.read(dashboardLayoutProvider.notifier);

      await notifier.reorder(0, 3);
      final state = container.read(dashboardLayoutProvider);

      expect(state.widgets.first.type, DashboardWidgetType.monthlySummary);
      expect(fakeRepo.saveCount, 1);
      expect(fakeRepo.currentLayout.widgets.first.type, DashboardWidgetType.monthlySummary);
    });

    test('toggleVisibility updates widget visibility and persists immediately', () async {
      final notifier = container.read(dashboardLayoutProvider.notifier);

      await notifier.toggleVisibility(DashboardWidgetType.budgets, false);
      final state = container.read(dashboardLayoutProvider);

      final budgetConfig = state.widgets.firstWhere((w) => w.type == DashboardWidgetType.budgets);
      expect(budgetConfig.isVisible, isFalse);
      expect(fakeRepo.saveCount, 1);
    });

    test('resetToDefault restores default layout and calls repository resetLayout', () async {
      final notifier = container.read(dashboardLayoutProvider.notifier);

      await notifier.toggleVisibility(DashboardWidgetType.balance, false);
      expect(container.read(dashboardLayoutProvider).widgets.first.isVisible, isFalse);

      await notifier.resetToDefault();
      final resetState = container.read(dashboardLayoutProvider);

      expect(resetState, DashboardLayout.defaultLayout());
      expect(fakeRepo.resetCount, 1);
    });
  });
}
