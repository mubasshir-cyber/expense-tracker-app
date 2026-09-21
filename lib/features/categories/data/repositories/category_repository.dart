import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    return user.id;
  }

  /// Returns all categories visible to the current user:
  /// system categories (user_id IS NULL) + user's own custom categories.
  /// RLS enforces this automatically — no client-side filter needed.
  Future<List<CategoryModel>> getCategories({
    String? type, // 'expense' | 'income' — null means all
  }) async {
    // Touch _userId to verify auth before making the request.
    _userId;

    var query = _client.from('categories').select();

    if (type != null) {
      final normalizedType =
          type.toUpperCase() == 'INCOME' ? 'CREDIT' : type.toUpperCase();
      query = query.eq('type', normalizedType);
    }

    final response = await query.order('name');

    return (response as List)
        .map(
          (row) => CategoryModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<CategoryModel> getCategory(String categoryId) async {
    _userId;

    final response = await _client
        .from('categories')
        .select()
        .eq('id', categoryId)
        .maybeSingle();

    if (response == null) {
      throw const PostgrestException(
        message: 'Category not found.',
      );
    }

    return CategoryModel.fromMap(response);
  }

  /// Creates a custom category owned by the current user.
  /// System categories (user_id = null) cannot be created by the client.
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final response = await _client
        .from('categories')
        .insert({
          'user_id': _userId,
          'name': name,
          'type': type.toUpperCase(),
          'icon': ?icon,
          'color': ?color,
        })
        .select()
        .single();

    return CategoryModel.fromMap(response);
  }

  /// Updates a user-owned category.
  /// System categories (user_id = null) are protected by RLS and cannot be mutated.
  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
  }) async {
    final updates = <String, dynamic>{
      'name': ?name,
      'icon': ?icon,
      'color': ?color,
    };

    if (updates.isEmpty) {
      return getCategory(categoryId);
    }

    final response = await _client
        .from('categories')
        .update(updates)
        .eq('id', categoryId)
        .eq('user_id', _userId)
        .select()
        .single();

    return CategoryModel.fromMap(response);
  }

  /// Soft-deletes a user-owned category.
  /// System categories are protected by RLS and cannot be deleted.
  Future<void> deleteCategory(String categoryId) async {
    await _client
        .from('categories')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', categoryId)
        .eq('user_id', _userId);
  }
}
