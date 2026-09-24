import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/savings_goal_repository.dart';
import '../../domain/models/goal_contribution_model.dart';
import '../../domain/models/goal_milestone.dart';
import '../../domain/models/goal_projection.dart';
import '../../domain/models/savings_goal_model.dart';
import '../../domain/services/savings_goal_calculation_service.dart';

/// Repository provider for savings goals.
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(Supabase.instance.client);
});

/// Domain calculation service provider for savings goals.
final savingsGoalCalculationServiceProvider =
    Provider<SavingsGoalCalculationService>((ref) {
  return const SavingsGoalCalculationService();
});

/// Fetches all active savings goals for the user.
final activeSavingsGoalsProvider =
    FutureProvider<List<SavingsGoalModel>>((ref) async {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.getGoals(activeOnly: true);
});

/// Fetches all savings goals (both active and paused/archived).
final allSavingsGoalsProvider =
    FutureProvider<List<SavingsGoalModel>>((ref) async {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.getGoals(activeOnly: false);
});

/// Derived provider for completed savings goals.
final completedSavingsGoalsProvider =
    FutureProvider<List<SavingsGoalModel>>((ref) async {
  final goals = await ref.watch(allSavingsGoalsProvider.future);
  return goals.where((g) => g.isCompleted).toList();
});

/// Derived portfolio summary across all active savings goals.
final savingsGoalsSummaryProvider =
    FutureProvider<SavingsGoalsSummary>((ref) async {
  final goals = await ref.watch(activeSavingsGoalsProvider.future);
  final calc = ref.watch(savingsGoalCalculationServiceProvider);
  return calc.calculateOverallSummary(goals);
});

/// Fetches detail for a single goal by ID.
final goalDetailProvider =
    FutureProvider.family<SavingsGoalModel?, String>((ref, id) async {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.getGoal(id);
});

/// Fetches contribution ledger history for a goal.
final goalContributionsProvider =
    FutureProvider.family<List<GoalContributionModel>, String>(
        (ref, goalId) async {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.getContributions(goalId);
});

/// Computes projection rate for a goal.
final goalProjectionProvider =
    Provider.family<GoalProjection, SavingsGoalModel>((ref, goal) {
  final calc = ref.watch(savingsGoalCalculationServiceProvider);
  return calc.calculateProjection(goal);
});

/// Computes milestones for a goal.
final goalMilestonesProvider =
    Provider.family<List<GoalMilestone>, SavingsGoalModel>((ref, goal) {
  final calc = ref.watch(savingsGoalCalculationServiceProvider);
  return calc.calculateMilestones(goal);
});

/// Controller for performing savings goal and contribution mutations.
final savingsGoalControllerProvider =
    StateNotifierProvider<SavingsGoalController, AsyncValue<void>>((ref) {
  return SavingsGoalController(ref);
});

class SavingsGoalController extends StateNotifier<AsyncValue<void>> {
  SavingsGoalController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  SavingsGoalRepository get _repo => _ref.read(savingsGoalRepositoryProvider);

  void _invalidateAll() {
    _ref.invalidate(activeSavingsGoalsProvider);
    _ref.invalidate(allSavingsGoalsProvider);
    _ref.invalidate(completedSavingsGoalsProvider);
    _ref.invalidate(savingsGoalsSummaryProvider);
  }

  /// Creates a new savings goal.
  Future<void> createGoal(SavingsGoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createGoal(goal);
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing savings goal.
  Future<void> updateGoal(SavingsGoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateGoal(goal);
      _invalidateAll();
      _ref.invalidate(goalDetailProvider(goal.id));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a savings goal.
  Future<void> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteGoal(id);
      _invalidateAll();
      _ref.invalidate(goalDetailProvider(id));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deposits an allocated amount to a goal.
  Future<void> addDeposit({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addContribution(
        goalId: goalId,
        amount: amount,
        accountId: accountId,
        notes: notes,
        date: date,
      );
      _invalidateAll();
      _ref.invalidate(goalDetailProvider(goalId));
      _ref.invalidate(goalContributionsProvider(goalId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Withdraws an allocated amount from a goal.
  Future<void> withdrawFunds({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.withdrawFromGoal(
        goalId: goalId,
        amount: amount,
        accountId: accountId,
        notes: notes,
        date: date,
      );
      _invalidateAll();
      _ref.invalidate(goalDetailProvider(goalId));
      _ref.invalidate(goalContributionsProvider(goalId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
