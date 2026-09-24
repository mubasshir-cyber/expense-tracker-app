import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/data/repositories/dashboard_layout_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_layout.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_widget_type.dart';
import 'package:expense_tracker/features/dashboard/presentation/customize_dashboard_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/dashboard_layout_provider.dart';

class FakeDashboardLayoutRepository implements DashboardLayoutRepository {
  DashboardLayout storedLayout = DashboardLayout.defaultLayout();

  @override
  Future<DashboardLayout> loadLayout() async => storedLayout;

  @override
  Future<void> saveLayout(DashboardLayout layout) async {
    storedLayout = layout;
  }

  @override
  Future<void> resetLayout() async {
    storedLayout = DashboardLayout.defaultLayout();
  }
}

void main() {
  testWidgets('CustomizeDashboardScreen renders all 8 widget tiles with toggle switches and reset buttons', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeDashboardLayoutRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardLayoutRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomizeDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar and instructions
    expect(find.text('Customize Dashboard'), findsOneWidget);
    expect(find.byKey(const Key('reset_dashboard_appbar_button')), findsOneWidget);
    expect(find.byKey(const Key('reset_dashboard_bottom_button')), findsOneWidget);

    // Verify all 8 widget titles are in the list
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('Monthly Summary'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Recurring Payments'), findsOneWidget);
    expect(find.text('Savings Goals'), findsOneWidget);
    expect(find.text('Debts & Loans'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
  });

  testWidgets('CustomizeDashboardScreen toggles widget visibility switch and immediately updates state', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeDashboardLayoutRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardLayoutRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomizeDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final balanceSwitchFinder = find.byKey(const Key('toggle_switch_balance'));
    expect(balanceSwitchFinder, findsOneWidget);

    // Initially ON
    final Switch initialSwitch = tester.widget(balanceSwitchFinder);
    expect(initialSwitch.value, isTrue);

    // Tap switch to turn OFF
    await tester.tap(balanceSwitchFinder);
    await tester.pumpAndSettle();

    final Switch updatedSwitch = tester.widget(balanceSwitchFinder);
    expect(updatedSwitch.value, isFalse);
    expect(fakeRepo.storedLayout.widgets.firstWhere((w) => w.type == DashboardWidgetType.balance).isVisible, isFalse);
  });

  testWidgets('CustomizeDashboardScreen shows reset dialog, cancels on Cancel, and restores on Reset', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeDashboardLayoutRepository();
    fakeRepo.storedLayout = fakeRepo.storedLayout.toggleVisibility(DashboardWidgetType.balance, false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardLayoutRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomizeDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Reset dialog via AppBar button
    await tester.tap(find.byKey(const Key('reset_dashboard_appbar_button')));
    await tester.pumpAndSettle();

    expect(find.text('Reset Dashboard?'), findsOneWidget);
    expect(
      find.text('Your widget order and visibility will be restored to the default dashboard.'),
      findsOneWidget,
    );

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Dashboard?'), findsNothing);
    expect(fakeRepo.storedLayout.widgets.firstWhere((w) => w.type == DashboardWidgetType.balance).isVisible, isFalse);

    // Open Reset dialog via Bottom button
    await tester.tap(find.byKey(const Key('reset_dashboard_bottom_button')));
    await tester.pumpAndSettle();

    expect(find.text('Reset Dashboard?'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Dashboard?'), findsNothing);
    expect(find.text('Dashboard layout restored to default.'), findsOneWidget);
    expect(fakeRepo.storedLayout.widgets.firstWhere((w) => w.type == DashboardWidgetType.balance).isVisible, isTrue);
  });
}
