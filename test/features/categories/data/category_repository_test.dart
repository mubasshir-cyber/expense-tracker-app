import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/categories/domain/models/category_model.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // CategoryRepository serialization contract tests.
  // Verifies both expense and credit (income) category types.
  // ──────────────────────────────────────────────────────────────────────────

  group('CategoryRepository — CategoryModel serialization', () {
    const expenseCategoryMap = {
      'id': 'cat-001',
      'user_id': 'user-123',
      'name': 'Food & Dining',
      'type': 'EXPENSE',
      'icon': '🍔',
      'color': '#EF4444',
      'is_active': true,
    };

    const creditCategoryMap = {
      'id': 'cat-002',
      'user_id': 'user-123',
      'name': 'Salary',
      'type': 'CREDIT',
      'icon': '💰',
      'color': '#10B981',
      'is_active': true,
    };

    test('fromMap parses expense category correctly', () {
      final model = CategoryModel.fromMap(expenseCategoryMap);

      expect(model.id, 'cat-001');
      expect(model.name, 'Food & Dining');
      expect(model.type, 'EXPENSE');
      expect(model.icon, '🍔');
      expect(model.color, '#EF4444');
      expect(model.isActive, isTrue);
    });

    test('fromMap parses credit category correctly', () {
      final model = CategoryModel.fromMap(creditCategoryMap);

      expect(model.id, 'cat-002');
      expect(model.name, 'Salary');
      expect(model.type, 'CREDIT');
    });

    test('fromMap defaults isActive to true when missing', () {
      final map = Map<String, dynamic>.from(expenseCategoryMap)
        ..remove('is_active');
      final model = CategoryModel.fromMap(map);

      expect(model.isActive, isTrue);
    });

    test('fromMap accepts null icon and color (system categories)', () {
      final map = Map<String, dynamic>.from(expenseCategoryMap)
        ..['icon'] = null
        ..['color'] = null;

      final model = CategoryModel.fromMap(map);

      expect(model.icon, isNull);
      expect(model.color, isNull);
    });

    test('toMap produces correct keys for Supabase insert', () {
      final model = CategoryModel.fromMap(expenseCategoryMap);
      final map = model.toMap();

      expect(map['id'], 'cat-001');
      expect(map['user_id'], 'user-123');
      expect(map['name'], 'Food & Dining');
      expect(map['type'], 'EXPENSE');
      expect(map['is_active'], isTrue);
    });

    test('fromMap → toMap round-trip preserves all fields', () {
      final original = CategoryModel.fromMap(creditCategoryMap);
      final roundTripped = CategoryModel.fromMap(original.toMap());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.type, original.type);
      expect(roundTripped.icon, original.icon);
      expect(roundTripped.color, original.color);
      expect(roundTripped.isActive, original.isActive);
    });

    test('copyWith updates name only', () {
      final original = CategoryModel.fromMap(expenseCategoryMap);
      final updated = original.copyWith(name: 'Groceries');

      expect(updated.name, 'Groceries');
      expect(updated.type, original.type);
      expect(updated.id, original.id);
    });

    test('copyWith soft-delete via isActive false', () {
      final original = CategoryModel.fromMap(expenseCategoryMap);
      final deleted = original.copyWith(isActive: false);

      expect(deleted.isActive, isFalse);
      expect(deleted.id, original.id);
    });

    test('expense type is distinct from credit type', () {
      final expense = CategoryModel.fromMap(expenseCategoryMap);
      final credit = CategoryModel.fromMap(creditCategoryMap);

      expect(expense.type, isNot(credit.type));
      expect(expense.type, 'EXPENSE');
      expect(credit.type, 'CREDIT');
    });
  });

  group('CategoryRepository — auth boundary contract', () {
    test('CategoryModel requires user_id field', () {
      expect(
        () => CategoryModel.fromMap({
          'id': 'cat-001',
          // 'user_id' deliberately omitted
          'name': 'Food',
          'type': 'EXPENSE',
          'is_active': true,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
