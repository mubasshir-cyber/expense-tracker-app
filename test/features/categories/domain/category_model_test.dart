import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('fromMap parses map with all fields', () {
      final map = {
        'id': 'cat-1',
        'user_id': 'user-1',
        'name': 'Food & Dining',
        'type': 'EXPENSE',
        'icon': 'utensils',
        'color': '#EF4444',
        'is_active': true,
      };

      final category = CategoryModel.fromMap(map);

      expect(category.id, equals('cat-1'));
      expect(category.userId, equals('user-1'));
      expect(category.name, equals('Food & Dining'));
      expect(category.type, equals('EXPENSE'));
      expect(category.icon, equals('utensils'));
      expect(category.color, equals('#EF4444'));
      expect(category.isActive, isTrue);
    });

    test('fromMap uses defaults for isActive when missing', () {
      final map = {
        'id': 'cat-2',
        'user_id': 'user-1',
        'name': 'Salary',
        'type': 'CREDIT',
      };

      final category = CategoryModel.fromMap(map);

      expect(category.id, equals('cat-2'));
      expect(category.name, equals('Salary'));
      expect(category.type, equals('CREDIT'));
      expect(category.isActive, isTrue);
      expect(category.icon, isNull);
      expect(category.color, isNull);
    });

    test('toMap produces database map correctly', () {
      const category = CategoryModel(
        id: 'cat-3',
        userId: 'user-1',
        name: 'Freelance',
        type: 'CREDIT',
        icon: 'briefcase',
        color: '#10B981',
        isActive: true,
      );

      final map = category.toMap();

      expect(map['id'], equals('cat-3'));
      expect(map['user_id'], equals('user-1'));
      expect(map['name'], equals('Freelance'));
      expect(map['type'], equals('CREDIT'));
      expect(map['icon'], equals('briefcase'));
      expect(map['color'], equals('#10B981'));
      expect(map['is_active'], isTrue);
    });

    test('copyWith updates specified fields', () {
      const category = CategoryModel(
        id: 'cat-1',
        userId: 'user-1',
        name: 'Dining',
        type: 'EXPENSE',
        isActive: true,
      );

      final updated = category.copyWith(name: 'Groceries & Dining', color: '#F59E0B');

      expect(updated.name, equals('Groceries & Dining'));
      expect(updated.color, equals('#F59E0B'));
      expect(updated.type, equals('EXPENSE'));
      expect(updated.id, equals('cat-1'));
    });
  });
}
