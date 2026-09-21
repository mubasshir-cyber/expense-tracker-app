import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/budget_model.dart';

class BudgetRepository {
  BudgetRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user.id;
  }

  /// Returns all budgets for the authenticated user, excluding soft-deleted rows.
  Future<List<BudgetModel>> getBudgets({bool activeOnly = false}) async {
    var query = _client
        .from('budgets')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => BudgetModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Fetches a single budget by ID.
  Future<BudgetModel?> getBudgetById(String id) async {
    final response = await _client
        .from('budgets')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return BudgetModel.fromMap(Map<String, dynamic>.from(response));
  }

  /// Creates a new budget in Supabase.
  Future<BudgetModel> createBudget({
    String? categoryId,
    required String name,
    required double amount,
    required String period,
    required DateTime startDate,
    DateTime? endDate,
    double alertThreshold = 0.80,
    bool isActive = true,
  }) async {
    final payload = {
      'user_id': _userId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'alert_threshold': alertThreshold,
      'is_active': isActive,
    };

    final response =
        await _client.from('budgets').insert(payload).select().single();

    return BudgetModel.fromMap(Map<String, dynamic>.from(response));
  }

  /// Updates an existing budget.
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    final payload = {
      'category_id': budget.categoryId,
      'name': budget.name,
      'amount': budget.amount,
      'period': budget.period.value,
      'start_date': budget.startDate.toIso8601String().split('T').first,
      'end_date': budget.endDate?.toIso8601String().split('T').first,
      'alert_threshold': budget.alertThreshold,
      'is_active': budget.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('budgets')
        .update(payload)
        .eq('id', budget.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return BudgetModel.fromMap(Map<String, dynamic>.from(response));
  }

  /// Toggles active status of a budget.
  Future<void> toggleBudgetActive(String id, bool isActive) async {
    await _client
        .from('budgets')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Soft deletes a budget by setting deleted_at.
  Future<void> deleteBudget(String id) async {
    await _client
        .from('budgets')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'is_active': false,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
