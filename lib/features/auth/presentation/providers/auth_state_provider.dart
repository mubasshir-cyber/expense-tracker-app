import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/auth_user.dart';
import 'auth_repository_provider.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);

  final currentUser = repository.currentUser;

  if (currentUser == null) {
    yield const AuthUnauthenticated();
  } else {
    yield AuthAuthenticated(currentUser);
  }

  yield* repository.authStateChanges.map(
    (user) {
      if (user == null) {
        return const AuthUnauthenticated();
      }

      return AuthAuthenticated(user);
    },
  );
});
