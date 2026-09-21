import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      throw const PostgrestException(
        message: 'Profile not found.',
      );
    }

    return UserProfile.fromMap(response);
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? currencyCode,
    String? currencySymbol,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    final updates = <String, dynamic>{
      'full_name': ?fullName,
      'avatar_url': ?avatarUrl,
      'currency_code': ?currencyCode,
      'currency_symbol': ?currencySymbol,
    };

    if (updates.isEmpty) {
      return getCurrentProfile();
    }

    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();

    return UserProfile.fromMap(response);
  }
}
