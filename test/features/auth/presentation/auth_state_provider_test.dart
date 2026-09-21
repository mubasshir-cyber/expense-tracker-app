import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/auth/domain/models/auth_user.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_state_provider.dart';

void main() {
  group('AuthState', () {
    test('AuthLoading can be created', () {
      const state = AuthLoading();

      expect(state, isA<AuthLoading>());
    });

    test('AuthUnauthenticated can be created', () {
      const state = AuthUnauthenticated();

      expect(state, isA<AuthUnauthenticated>());
    });

    test('AuthAuthenticated contains the user', () {
      const user = AuthUser(
        id: 'user-1',
        email: 'test@example.com',
      );

      const state = AuthAuthenticated(user);

      expect(state.user.id, 'user-1');
      expect(state.user.email, 'test@example.com');
    });
  });
}
