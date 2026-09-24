import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/goal_contribution_model.dart';
import '../../domain/models/savings_goal_model.dart';

class SavingsGoalRepository {
  SavingsGoalRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user.id;
  }

  /// Returns all savings goals for the current user with balances derived from the contribution ledger.
  Future<List<SavingsGoalModel>> getGoals({bool activeOnly = true}) async {
    var query = _client
        .from('savings_goals')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('created_at', ascending: false);
    final rawGoals = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    if (rawGoals.isEmpty) return [];

    // Fetch all active contributions to compute accurate goal balances
    final contributionsResponse = await _client
        .from('goal_contributions')
        .select('goal_id, amount')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    final balanceMap = <String, double>{};
    for (final row in contributionsResponse as List) {
      final gId = row['goal_id'] as String;
      final amt = (row['amount'] as num).toDouble();
      balanceMap[gId] = (balanceMap[gId] ?? 0.0) + amt;
    }

    return rawGoals.map((map) {
      final goalId = map['id'] as String;
      final balance = balanceMap[goalId] ?? 0.0;
      return SavingsGoalModel.fromMap(map, currentAmount: balance);
    }).toList();
  }

  /// Returns a single savings goal with its balance derived from the contribution ledger.
  Future<SavingsGoalModel?> getGoal(String id) async {
    final response = await _client
        .from('savings_goals')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;

    final balance = await getGoalBalance(id);
    return SavingsGoalModel.fromMap(
      Map<String, dynamic>.from(response),
      currentAmount: balance,
    );
  }

  /// Returns the current accumulated saved balance for a specific goal.
  Future<double> getGoalBalance(String goalId) async {
    final response = await _client
        .from('goal_contributions')
        .select('amount')
        .eq('goal_id', goalId)
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    var total = 0.0;
    for (final row in response as List) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }

  /// Creates a new savings goal in the database.
  Future<SavingsGoalModel> createGoal(SavingsGoalModel goal) async {
    final payload = {
      'user_id': _userId,
      'name': goal.name,
      'target_amount': goal.targetAmount,
      'target_date': goal.targetDate?.toIso8601String().split('T').first,
      'icon': goal.icon,
      'color': goal.color,
      'account_id': goal.accountId,
      'category_id': goal.categoryId,
      'is_active': goal.isActive,
      'notes': goal.notes,
    };

    final response = await _client
        .from('savings_goals')
        .insert(payload)
        .select()
        .single();

    return SavingsGoalModel.fromMap(
      Map<String, dynamic>.from(response),
      currentAmount: 0.0,
    );
  }

  /// Updates an existing savings goal.
  Future<SavingsGoalModel> updateGoal(SavingsGoalModel goal) async {
    final payload = {
      'name': goal.name,
      'target_amount': goal.targetAmount,
      'target_date': goal.targetDate?.toIso8601String().split('T').first,
      'icon': goal.icon,
      'color': goal.color,
      'account_id': goal.accountId,
      'category_id': goal.categoryId,
      'is_active': goal.isActive,
      'notes': goal.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('savings_goals')
        .update(payload)
        .eq('id', goal.id)
        .eq('user_id', _userId)
        .select()
        .single();

    final balance = await getGoalBalance(goal.id);
    return SavingsGoalModel.fromMap(
      Map<String, dynamic>.from(response),
      currentAmount: balance,
    );
  }

  /// Soft deletes a savings goal.
  Future<void> deleteGoal(String id) async {
    await _client
        .from('savings_goals')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Returns contribution ledger history for a goal (newest first).
  Future<List<GoalContributionModel>> getContributions(String goalId) async {
    final response = await _client
        .from('goal_contributions')
        .select()
        .eq('goal_id', goalId)
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('contribution_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => GoalContributionModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Adds a deposit contribution to a savings goal (+amount).
  Future<GoalContributionModel> addContribution({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
    DateTime? date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Deposit amount must be greater than zero.');
    }

    final contributionDate = date ?? DateTime.now();
    final payload = {
      'goal_id': goalId,
      'user_id': _userId,
      'account_id': accountId,
      'amount': amount,
      'contribution_date': contributionDate.toIso8601String().split('T').first,
      'notes': notes,
    };

    final response = await _client
        .from('goal_contributions')
        .insert(payload)
        .select()
        .single();

    return GoalContributionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Adds a withdrawal allocation from a savings goal (-amount).
  /// Enforces that withdrawal cannot exceed current accumulated goal balance.
  Future<GoalContributionModel> withdrawFromGoal({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
    DateTime? date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Withdrawal amount must be greater than zero.');
    }

    final currentBalance = await getGoalBalance(goalId);
    if (amount > currentBalance) {
      throw ArgumentError(
        'Withdrawal amount ($amount) exceeds current goal balance ($currentBalance).',
      );
    }

    final contributionDate = date ?? DateTime.now();
    final payload = {
      'goal_id': goalId,
      'user_id': _userId,
      'account_id': accountId,
      'amount': -amount, // stored as negative value
      'contribution_date': contributionDate.toIso8601String().split('T').first,
      'notes': notes,
    };

    final response = await _client
        .from('goal_contributions')
        .insert(payload)
        .select()
        .single();

    return GoalContributionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}
