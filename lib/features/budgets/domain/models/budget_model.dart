import 'budget_period.dart';

/// Immutable representation of a user spending limit/budget.
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.alertThreshold = 0.80,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? categoryId; // Null indicates overall monthly/period budget
  final String name;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final double alertThreshold;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverallBudget => categoryId == null || categoryId!.isEmpty;

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: BudgetPeriod.fromValue(map['period'] as String? ?? 'MONTHLY'),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      alertThreshold: map['alert_threshold'] != null
          ? (map['alert_threshold'] as num).toDouble()
          : 0.80,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'period': period.value,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'alert_threshold': alertThreshold,
      'is_active': isActive,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    bool clearCategoryId = false,
    String? name,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          categoryId == other.categoryId &&
          name == other.name &&
          amount == other.amount &&
          period == other.period &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          alertThreshold == other.alertThreshold &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      categoryId.hashCode ^
      name.hashCode ^
      amount.hashCode ^
      period.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      alertThreshold.hashCode ^
      isActive.hashCode;
}
