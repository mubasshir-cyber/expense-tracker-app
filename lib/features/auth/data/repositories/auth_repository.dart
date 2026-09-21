import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  AuthUser? get currentUser {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _mapUser(user);
  }

  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Unable to create account.',
      );
    }

    return _mapUser(user);
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Unable to sign in.',
      );
    }

    return _mapUser(user);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Stream<AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map(
      (event) => event.session?.user == null
          ? null
          : _mapUser(event.session!.user),
    );
  }

  AuthUser _mapUser(User user) {
    DateTime? emailConfirmedAt;
    final confirmedAtStr = user.emailConfirmedAt;
    if (confirmedAtStr != null) {
      emailConfirmedAt = DateTime.tryParse(confirmedAtStr);
    }

    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      emailConfirmedAt: emailConfirmedAt,
    );
  }
}
