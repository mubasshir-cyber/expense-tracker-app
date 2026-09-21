import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';

/// Filter parameters for querying transactions.
class TransactionFilter {
  const TransactionFilter({
    this.accountId,
    this.categoryId,
    this.type,
    this.from,
    this.to,
    this.limit,
    this.offset,
  });

  final String? accountId;
  final String? categoryId;
  final TransactionType? type;
  final DateTime? from;
  final DateTime? to;
  final int? limit;
  final int? offset;
}

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    return user.id;
  }

  /// Returns transactions for the current user, newest first.
  /// Optionally filtered by account, category, type, or date range.
  Future<List<TransactionModel>> getTransactions({
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    // Build filter chain (PostgrestFilterBuilder).
    // Exclude soft-deleted transactions (deleted_at IS NULL).
    var filterQuery = _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    if (filter.accountId != null) {
      filterQuery = filterQuery.eq('account_id', filter.accountId!);
    }

    if (filter.categoryId != null) {
      filterQuery = filterQuery.eq('category_id', filter.categoryId!);
    }

    if (filter.type != null) {
      filterQuery = filterQuery.eq('type', filter.type!.value);
    }

    if (filter.from != null) {
      filterQuery = filterQuery.gte(
        'transaction_date',
        filter.from!.toIso8601String(),
      );
    }

    if (filter.to != null) {
      filterQuery = filterQuery.lte(
        'transaction_date',
        filter.to!.toIso8601String(),
      );
    }

    // order() transitions to PostgrestTransformBuilder — chain terminal ops.
    final transformQuery = filterQuery.order(
      'transaction_date',
      ascending: false,
    );

    final limitedQuery = filter.limit != null
        ? transformQuery.limit(filter.limit!)
        : transformQuery;

    final pagedQuery = filter.offset != null
        ? limitedQuery.range(
            filter.offset!,
            filter.offset! + (filter.limit ?? 50) - 1,
          )
        : limitedQuery;

    final response = await pagedQuery;

    return (response as List)
        .map(
          (row) => TransactionModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) {
      throw const PostgrestException(
        message: 'Transaction not found.',
      );
    }

    return TransactionModel.fromMap(response);
  }

  Future<TransactionModel> createTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final response = await _client
        .from('transactions')
        .insert({
          'user_id': _userId,
          'account_id': accountId,
          'category_id': categoryId,
          'type': type.value,
          'amount': amount,
          'transaction_date': date.toUtc().toIso8601String(),
          'description': ?note,
        })
        .select()
        .single();

    return TransactionModel.fromMap(response);
  }

  Future<TransactionModel> updateTransaction({
    required String transactionId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'account_id': ?accountId,
      'category_id': ?categoryId,
      if (type != null) 'type': type.value,
      'amount': ?amount,
      if (date != null)
        'transaction_date': date.toUtc().toIso8601String(),
      'description': ?note,
    };

    if (updates.isEmpty) {
      return getTransaction(transactionId);
    }

    final response = await _client
        .from('transactions')
        .update(updates)
        .eq('id', transactionId)
        .eq('user_id', _userId)
        .select()
        .single();

    return TransactionModel.fromMap(response);
  }

  /// Soft-deletes a transaction.
  /// Hard DELETE is disabled to preserve the audit trail.
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('transactions')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', transactionId)
        .eq('user_id', _userId);
  }

  /// Returns the total sum of a given [type] within an optional date range.
  /// Used by the financial calculation service to derive balances.
  Future<double> sumByType({
    required TransactionType type,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('transactions')
        .select('amount')
        .eq('user_id', _userId)
        .eq('type', type.value)
        .isFilter('deleted_at', null);

    if (accountId != null) {
      query = query.eq('account_id', accountId);
    }

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (from != null) {
      query = query.gte('transaction_date', from.toIso8601String());
    }

    if (to != null) {
      query = query.lte('transaction_date', to.toIso8601String());
    }

    final response = await query;

    return (response as List).fold<double>(
      0.0,
      (sum, row) {
        final raw = (row as Map)['amount'];
        return sum + (raw is int ? raw.toDouble() : (raw as double));
      },
    );
  }
}
