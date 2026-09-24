import 'package:flutter/foundation.dart';

@immutable
class KhataCustomerModel {
  const KhataCustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  KhataCustomerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return KhataCustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory KhataCustomerModel.fromMap(Map<String, dynamic> map) {
    return KhataCustomerModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String?,
      notes: map['notes'] as String?,
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
      other is KhataCustomerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          phone == other.phone &&
          address == other.address &&
          notes == other.notes &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      notes.hashCode ^
      deletedAt.hashCode;

  @override
  String toString() =>
      'KhataCustomerModel(id: $id, name: $name, phone: $phone, isDeleted: $isDeleted)';
}
