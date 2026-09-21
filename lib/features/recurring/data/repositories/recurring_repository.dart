import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../transactions/domain/models/transaction_type.dart';
import '../../domain/models/recurring_transaction_model.dart';

class RecurringRepository {
  RecurringRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user.id;
  }

  /// Returns all recurring transaction templates for the user, excluding soft-deleted rows.
  Future<List<RecurringTransactionModel>> getRecurringTransactions({
    bool activeOnly = false,
  }) async {
    var query = _client
        .from('recurring_transactions')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('next_occurrence', ascending: true);

    return (response as List)
        .map(
          (row) => RecurringTransactionModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Fetches a single recurring transaction by ID.
  Future<RecurringTransactionModel?> getRecurringById(String id) async {
    final response = await _client
        .from('recurring_transactions')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return RecurringTransactionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Creates a new recurring transaction template.
  Future<RecurringTransactionModel> createRecurringTransaction({
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    required String description,
    required String frequency,
    required DateTime startDate,
    required DateTime nextOccurrence,
    DateTime? endDate,
    bool isActive = true,
    bool autoCreate = false,
  }) async {
    final payload = {
      'user_id': _userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'frequency': frequency,
      'start_date': startDate.toIso8601String().split('T').first,
      'next_occurrence': nextOccurrence.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': isActive,
      'auto_create': autoCreate,
    };

    final response = await _client
        .from('recurring_transactions')
        .insert(payload)
        .select()
        .single();

    return RecurringTransactionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Updates an existing recurring transaction template.
  Future<RecurringTransactionModel> updateRecurringTransaction(
    RecurringTransactionModel item,
  ) async {
    final payload = {
      'account_id': item.accountId,
      'category_id': item.categoryId,
      'type': item.type.value,
      'amount': item.amount,
      'description': item.description,
      'frequency': item.frequency.value,
      'start_date': item.startDate.toIso8601String().split('T').first,
      'next_occurrence': item.nextOccurrence.toIso8601String().split('T').first,
      'end_date': item.endDate?.toIso8601String().split('T').first,
      'is_active': item.isActive,
      'auto_create': item.autoCreate,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('recurring_transactions')
        .update(payload)
        .eq('id', item.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return RecurringTransactionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Advances next_occurrence after recording a transaction.
  Future<void> advanceNextOccurrence(
    String id,
    DateTime nextDate, {
    bool isActive = true,
  }) async {
    await _client
        .from('recurring_transactions')
        .update({
          'next_occurrence': nextDate.toIso8601String().split('T').first,
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Toggles active status of a recurring template.
  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from('recurring_transactions')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Soft deletes a recurring transaction template.
  Future<void> deleteRecurringTransaction(String id) async {
    await _client
        .from('recurring_transactions')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'is_active': false,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
