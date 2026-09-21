import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // These tests verify AccountRepository's data contract:
  // the exact map structure it sends to / receives from Supabase.
  // They guard against silent schema drift.
  // ──────────────────────────────────────────────────────────────────────────

  group('AccountRepository — AccountModel serialization', () {
    const baseMap = {
      'id': 'acct-001',
      'user_id': 'user-123',
      'name': 'Savings Account',
      'type': 'savings',
      'icon': '🏦',
      'color': '#10B981',
      'is_active': true,
    };

    test('fromMap maps all fields correctly', () {
      final model = AccountModel.fromMap(baseMap);

      expect(model.id, 'acct-001');
      expect(model.userId, 'user-123');
      expect(model.name, 'Savings Account');
      expect(model.type, 'savings');
      expect(model.icon, '🏦');
      expect(model.color, '#10B981');
      expect(model.isActive, isTrue);
    });

    test('fromMap defaults isActive to true when missing', () {
      final map = Map<String, dynamic>.from(baseMap)..remove('is_active');
      final model = AccountModel.fromMap(map);

      expect(model.isActive, isTrue);
    });

    test('fromMap accepts null icon and color', () {
      final map = Map<String, dynamic>.from(baseMap)
        ..['icon'] = null
        ..['color'] = null;

      final model = AccountModel.fromMap(map);

      expect(model.icon, isNull);
      expect(model.color, isNull);
    });

    test('toMap produces correct keys for Supabase insert', () {
      final model = AccountModel.fromMap(baseMap);
      final map = model.toMap();

      expect(map['id'], 'acct-001');
      expect(map['user_id'], 'user-123');
      expect(map['name'], 'Savings Account');
      expect(map['type'], 'savings');
      expect(map['icon'], '🏦');
      expect(map['color'], '#10B981');
      expect(map['is_active'], isTrue);
    });

    test('fromMap → toMap round-trip preserves all fields', () {
      final original = AccountModel.fromMap(baseMap);
      final roundTripped = AccountModel.fromMap(original.toMap());

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.name, original.name);
      expect(roundTripped.type, original.type);
      expect(roundTripped.icon, original.icon);
      expect(roundTripped.color, original.color);
      expect(roundTripped.isActive, original.isActive);
    });

    test('copyWith updates name only', () {
      final original = AccountModel.fromMap(baseMap);
      final updated = original.copyWith(name: 'Current Account');

      expect(updated.name, 'Current Account');
      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.isActive, original.isActive);
    });

    test('copyWith soft-delete sets isActive to false', () {
      final original = AccountModel.fromMap(baseMap);
      final deleted = original.copyWith(isActive: false);

      expect(deleted.isActive, isFalse);
      expect(deleted.id, original.id);
    });
  });

  group('AccountRepository — auth boundary contract', () {
    test('AccountModel requires user_id in map (RLS identity field)', () {
      // If user_id is missing, fromMap must throw — this guards the identity
      // contract: every account row must belong to exactly one user.
      expect(
        () => AccountModel.fromMap({
          'id': 'acct-001',
          // 'user_id' deliberately omitted
          'name': 'Test',
          'type': 'savings',
          'is_active': true,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
