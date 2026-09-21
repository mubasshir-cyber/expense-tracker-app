import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromMap parses map with all fields', () {
      final map = {
        'id': 'user-123',
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'avatar_url': 'https://example.com/avatar.png',
        'currency_code': 'USD',
        'currency_symbol': '\$',
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, equals('user-123'));
      expect(profile.fullName, equals('John Doe'));
      expect(profile.email, equals('john@example.com'));
      expect(profile.avatarUrl, equals('https://example.com/avatar.png'));
      expect(profile.currencyCode, equals('USD'));
      expect(profile.currencySymbol, equals('\$'));
    });

    test('fromMap uses defaults for currency when missing', () {
      final map = {
        'id': 'user-456',
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, equals('user-456'));
      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.currencyCode, equals('INR'));
      expect(profile.currencySymbol, equals('₹'));
    });

    test('toMap produces correct database structure', () {
      const profile = UserProfile(
        id: 'user-789',
        fullName: 'Alice',
        email: 'alice@example.com',
        currencyCode: 'EUR',
        currencySymbol: '€',
      );

      final map = profile.toMap();

      expect(map['id'], equals('user-789'));
      expect(map['full_name'], equals('Alice'));
      expect(map['email'], equals('alice@example.com'));
      expect(map['avatar_url'], isNull);
      expect(map['currency_code'], equals('EUR'));
      expect(map['currency_symbol'], equals('€'));
    });

    test('copyWith updates specified fields', () {
      const profile = UserProfile(
        id: 'user-1',
        fullName: 'Bob',
        currencyCode: 'INR',
        currencySymbol: '₹',
      );

      final updated = profile.copyWith(fullName: 'Bob Smith', currencyCode: 'USD');

      expect(updated.fullName, equals('Bob Smith'));
      expect(updated.currencyCode, equals('USD'));
      expect(updated.currencySymbol, equals('₹'));
      expect(updated.id, equals('user-1'));
    });
  });
}
