import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';

void main() {
  group('AccountModel', () {
    test('fromMap parses map with all fields', () {
      final map = {
        'id': 'acc-1',
        'user_id': 'user-1',
        'name': 'HDFC Salary Bank',
        'type': 'BANK',
        'icon': 'landmark',
        'color': '#3B82F6',
        'is_active': true,
      };

      final account = AccountModel.fromMap(map);

      expect(account.id, equals('acc-1'));
      expect(account.userId, equals('user-1'));
      expect(account.name, equals('HDFC Salary Bank'));
      expect(account.type, equals('BANK'));
      expect(account.icon, equals('landmark'));
      expect(account.color, equals('#3B82F6'));
      expect(account.isActive, isTrue);
    });

    test('fromMap uses defaults for isActive when missing', () {
      final map = {
        'id': 'acc-2',
        'user_id': 'user-1',
        'name': 'Cash in Wallet',
        'type': 'CASH',
      };

      final account = AccountModel.fromMap(map);

      expect(account.id, equals('acc-2'));
      expect(account.name, equals('Cash in Wallet'));
      expect(account.type, equals('CASH'));
      expect(account.isActive, isTrue);
      expect(account.icon, isNull);
      expect(account.color, isNull);
    });

    test('toMap produces database map correctly', () {
      const account = AccountModel(
        id: 'acc-3',
        userId: 'user-1',
        name: 'GPay UPI',
        type: 'UPI',
        icon: 'smartphone',
        color: '#10B981',
        isActive: false,
      );

      final map = account.toMap();

      expect(map['id'], equals('acc-3'));
      expect(map['user_id'], equals('user-1'));
      expect(map['name'], equals('GPay UPI'));
      expect(map['type'], equals('UPI'));
      expect(map['icon'], equals('smartphone'));
      expect(map['color'], equals('#10B981'));
      expect(map['is_active'], isFalse);
    });

    test('copyWith updates specified fields', () {
      const account = AccountModel(
        id: 'acc-1',
        userId: 'user-1',
        name: 'Bank',
        type: 'BANK',
        isActive: true,
      );

      final updated = account.copyWith(name: 'Main Bank Account', color: '#000000');

      expect(updated.name, equals('Main Bank Account'));
      expect(updated.color, equals('#000000'));
      expect(updated.type, equals('BANK'));
      expect(updated.id, equals('acc-1'));
    });
  });
}
