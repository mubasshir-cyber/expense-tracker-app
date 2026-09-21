import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/account_model.dart';

class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    return user.id;
  }

  Future<List<AccountModel>> getAccounts({
    bool activeOnly = true,
  }) async {
    var query = _client
        .from('accounts')
        .select()
        .eq('user_id', _userId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');

    return (response as List)
        .map(
          (row) => AccountModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<AccountModel> getAccount(String accountId) async {
    final response = await _client
        .from('accounts')
        .select()
        .eq('id', accountId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) {
      throw const PostgrestException(
        message: 'Account not found.',
      );
    }

    return AccountModel.fromMap(response);
  }

  Future<AccountModel> createAccount({
    required String name,
    required String type,
    String? icon,
    String? color,
    double openingBalance = 0.00,
  }) async {
    final response = await _client
        .from('accounts')
        .insert({
          'user_id': _userId,
          'name': name,
          'type': type,
          'icon': ?icon,
          'color': ?color,
          'opening_balance': openingBalance,
          'is_active': true,
        })
        .select()
        .single();

    return AccountModel.fromMap(response);
  }

  Future<AccountModel> updateAccount({
    required String accountId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'name': ?name,
      'type': ?type,
      'icon': ?icon,
      'color': ?color,
      'is_active': ?isActive,
    };

    if (updates.isEmpty) {
      return getAccount(accountId);
    }

    final response = await _client
        .from('accounts')
        .update(updates)
        .eq('id', accountId)
        .eq('user_id', _userId)
        .select()
        .single();

    return AccountModel.fromMap(response);
  }

  /// Soft-deletes an account by setting deleted_at and marking it inactive.
  /// Hard DELETE is disabled per the schema's audit trail design.
  Future<void> deleteAccount(String accountId) async {
    await _client
        .from('accounts')
        .update({
          'is_active': false,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', accountId)
        .eq('user_id', _userId);
  }
}
