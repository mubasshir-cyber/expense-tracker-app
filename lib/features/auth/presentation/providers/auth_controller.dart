import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_repository_provider.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  late final AuthRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.read(authRepositoryProvider);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _repository.signIn(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _repository.signUp(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _repository.signOut,
    );
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _repository.deleteAccount,
    );
  }

  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _repository.resetPassword(
        email: email,
        redirectTo: redirectTo,
      ),
    );
  }
}
