import 'package:expense_tracker/features/khata/data/models/khata_customer_model.dart';
import 'package:expense_tracker/features/khata/data/models/khata_entry_model.dart';
import 'package:expense_tracker/features/khata/domain/models/khata_entry_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KhataCustomerModel serialization & copyWith', () {
    test('Converts toMap and fromMap accurately', () {
      final now = DateTime(2026, 9, 24, 10, 30);
      final customer = KhataCustomerModel(
        id: 'cust-1',
        userId: 'user-1',
        name: 'Ahmed',
        phone: '9876543210',
        address: 'MG Road',
        notes: 'Wholesale client',
        createdAt: now,
      );

      final map = customer.toMap();
      expect(map['name'], 'Ahmed');
      expect(map['phone'], '9876543210');
      expect(map['address'], 'MG Road');
      expect(map['notes'], 'Wholesale client');
      expect(map['user_id'], 'user-1');

      final fromMap = KhataCustomerModel.fromMap(map);
      expect(fromMap.id, 'cust-1');
      expect(fromMap.name, 'Ahmed');
      expect(fromMap.phone, '9876543210');
      expect(fromMap.address, 'MG Road');
      expect(fromMap.notes, 'Wholesale client');
      expect(fromMap.isDeleted, isFalse);
    });

    test('copyWith updates specified fields only', () {
      final customer = KhataCustomerModel(
        id: 'cust-1',
        userId: 'user-1',
        name: 'Ahmed',
        phone: '9876543210',
        createdAt: DateTime.now(),
      );

      final updated = customer.copyWith(name: 'Ahmed Khan', phone: '9999999999');
      expect(updated.name, 'Ahmed Khan');
      expect(updated.phone, '9999999999');
      expect(updated.id, 'cust-1');
      expect(updated.userId, 'user-1');
    });
  });

  group('KhataEntryModel serialization & copyWith', () {
    test('Converts toMap and fromMap accurately', () {
      final now = DateTime(2026, 9, 24, 12, 0);
      final entry = KhataEntryModel(
        id: 'entry-1',
        userId: 'user-1',
        customerId: 'cust-1',
        type: KhataEntryType.given,
        amount: 800.0,
        isOpeningBalance: true,
        description: 'Opening Due',
        entryDate: DateTime(2026, 9, 24),
        createdAt: now,
      );

      final map = entry.toMap();
      expect(map['amount'], 800.0);
      expect(map['type'], 'GIVEN');
      expect(map['is_opening_balance'], isTrue);
      expect(map['customer_id'], 'cust-1');

      final fromMap = KhataEntryModel.fromMap(map);
      expect(fromMap.id, 'entry-1');
      expect(fromMap.amount, 800.0);
      expect(fromMap.type, KhataEntryType.given);
      expect(fromMap.isOpeningBalance, isTrue);
      expect(fromMap.description, 'Opening Due');
    });

    test('KhataEntryType parses given, received, and fallback correctly', () {
      expect(KhataEntryType.fromString('GIVEN'), KhataEntryType.given);
      expect(KhataEntryType.fromString('RECEIVED'), KhataEntryType.received);
      expect(KhataEntryType.fromString('payment'), KhataEntryType.received);
      expect(KhataEntryType.fromString('got'), KhataEntryType.received);
      expect(KhataEntryType.fromString('unknown'), KhataEntryType.given);
      expect(KhataEntryType.fromString(null), KhataEntryType.given);
    });
  });
}
