import '../../../transactions/domain/models/transaction_type.dart';
import 'recurring_frequency.dart';

/// Immutable representation of a recurring transaction template.
class RecurringTransactionModel {
  const RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    required this.frequency,
    required this.startDate,
    required this.nextOccurrence,
    this.endDate,
    this.isActive = true,
    this.autoCreate = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final String description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextOccurrence;
  final DateTime? endDate;
  final bool isActive;
  final bool autoCreate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpense => type == TransactionType.expense;
  bool get isCredit => type == TransactionType.credit;

  /// Returns true if this recurring item is active and due on or before [asOf] date.
  bool isDue([DateTime? asOf]) {
    if (!isActive) return false;
    final checkDate = asOf ?? DateTime.now();
    final today = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final occurrence = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );
    if (occurrence.isAfter(today)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (occurrence.isAfter(end)) return false;
    }
    return true;
  }

  /// Calculates the next occurrence date after the current nextOccurrence.
  DateTime computeNextCycleDate() {
    return frequency.calculateNextOccurrence(nextOccurrence);
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String,
      type: TransactionTypeX.fromValue(map['type'] as String? ?? 'EXPENSE'),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      frequency: RecurringFrequency.fromValue(
        map['frequency'] as String? ?? 'MONTHLY',
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      nextOccurrence: DateTime.parse(map['next_occurrence'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
      autoCreate: map['auto_create'] as bool? ?? false,
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
      'account_id': accountId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'frequency': frequency.value,
      'start_date': startDate.toIso8601String().split('T').first,
      'next_occurrence': nextOccurrence.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': isActive,
      'auto_create': autoCreate,
    };
  }

  RecurringTransactionModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextOccurrence,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isActive,
    bool? autoCreate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isActive: isActive ?? this.isActive,
      autoCreate: autoCreate ?? this.autoCreate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          accountId == other.accountId &&
          categoryId == other.categoryId &&
          type == other.type &&
          amount == other.amount &&
          description == other.description &&
          frequency == other.frequency &&
          startDate == other.startDate &&
          nextOccurrence == other.nextOccurrence &&
          endDate == other.endDate &&
          isActive == other.isActive &&
          autoCreate == other.autoCreate;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      accountId.hashCode ^
      categoryId.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      description.hashCode ^
      frequency.hashCode ^
      startDate.hashCode ^
      nextOccurrence.hashCode ^
      endDate.hashCode ^
      isActive.hashCode ^
      autoCreate.hashCode;
}
