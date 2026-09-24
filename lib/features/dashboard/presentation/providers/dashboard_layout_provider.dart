import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_layout_repository.dart';
import '../../domain/models/dashboard_layout.dart';
import '../../domain/models/dashboard_widget_type.dart';

final dashboardLayoutRepositoryProvider = Provider<DashboardLayoutRepository>((ref) {
  return SharedPreferencesDashboardLayoutRepository();
});

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  DashboardLayoutNotifier(this._repository) : super(DashboardLayout.defaultLayout()) {
    _init();
  }

  final DashboardLayoutRepository _repository;
  bool _initialized = false;

  Future<void> _init() async {
    final loaded = await _repository.loadLayout();
    if (mounted && !_initialized) {
      state = loaded;
      _initialized = true;
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    _initialized = true;
    final updated = state.reorder(oldIndex, newIndex);
    state = updated;
    await _repository.saveLayout(updated);
  }

  Future<void> toggleVisibility(DashboardWidgetType type, bool isVisible) async {
    _initialized = true;
    final updated = state.toggleVisibility(type, isVisible);
    state = updated;
    await _repository.saveLayout(updated);
  }

  Future<void> resetToDefault() async {
    _initialized = true;
    final defaultLayout = DashboardLayout.defaultLayout();
    state = defaultLayout;
    await _repository.resetLayout();
  }

  Future<void> reload() async {
    final loaded = await _repository.loadLayout();
    if (mounted) {
      state = loaded;
      _initialized = true;
    }
  }
}

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>((ref) {
  final repository = ref.watch(dashboardLayoutRepositoryProvider);
  return DashboardLayoutNotifier(repository);
});
