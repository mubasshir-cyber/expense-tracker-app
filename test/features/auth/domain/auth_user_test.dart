import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/auth/domain/models/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('isEmailConfirmed is false when emailConfirmedAt is null', () {
      const user = AuthUser(
        id: 'user-1',
        email: 'test@example.com',
      );

      expect(user.isEmailConfirmed, isFalse);
    });

    test('isEmailConfirmed is true when emailConfirmedAt exists', () {
      final user = AuthUser(
        id: 'user-1',
        email: 'test@example.com',
        emailConfirmedAt: DateTime(2026, 9, 20),
      );

      expect(user.isEmailConfirmed, isTrue);
    });

    test('toString includes key fields', () {
      const user = AuthUser(
        id: 'user-1',
        email: 'test@example.com',
      );

      expect(user.toString(), contains('user-1'));
      expect(user.toString(), contains('test@example.com'));
    });
  });
}
