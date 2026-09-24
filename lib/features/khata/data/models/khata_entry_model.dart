import 'package:flutter/foundation.dart';
import '../../domain/models/khata_entry_type.dart';

@immutable
class KhataEntryModel {
  const KhataEntryModel({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.type,
    required this.amount,
    this.description,
    required this.entryDate,
    this.isOpeningBalance = false,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String customerId;
  final KhataEntryType type;
  final double amount;
  final String? description;
  final DateTime entryDate;
  final bool isOpeningBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isGiven => type == KhataEntryType.given;
  bool get isReceived => type == KhataEntryType.received;

  KhataEntryModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    KhataEntryType? type,
    double? amount,
    String? description,
    DateTime? entryDate,
    bool? isOpeningBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return KhataEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      entryDate: entryDate ?? this.entryDate,
      isOpeningBalance: isOpeningBalance ?? this.isOpeningBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'entry_date': entryDate.toIso8601String().split('T').first,
      'is_opening_balance': isOpeningBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory KhataEntryModel.fromMap(Map<String, dynamic> map) {
    return KhataEntryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      customerId: map['customer_id'] as String,
      type: KhataEntryType.fromString(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      entryDate: map['entry_date'] != null
          ? DateTime.parse(map['entry_date'] as String).toLocal()
          : DateTime.now(),
      isOpeningBalance: (map['is_opening_balance'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String).toLocal()
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataEntryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          customerId == other.customerId &&
          type == other.type &&
          amount == other.amount &&
          description == other.description &&
          entryDate == other.entryDate &&
          isOpeningBalance == other.isOpeningBalance &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      customerId.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      description.hashCode ^
      entryDate.hashCode ^
      isOpeningBalance.hashCode ^
      deletedAt.hashCode;

  @override
  String toString() =>
      'KhataEntryModel(id: $id, type: ${type.name}, amount: $amount, date: $entryDate)';
}
