import 'debt_installment_model.dart';
import 'debt_repayment_model.dart';
import 'debt_status.dart';
import 'debt_type.dart';
import 'interest_type.dart';

/// Immutable domain entity representing a debt (Liability / You Owe) or a loan (Asset / You Are Owed).
class DebtModel {
  const DebtModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.personName,
    this.contactNumber,
    required this.principalAmount,
    this.interestType = InterestType.none,
    this.interestRate = 0.0,
    this.interestAmount = 0.0,
    required this.totalRepaymentAmount,
    this.dueDate,
    this.status = DebtStatus.active,
    this.accountId,
    this.notes,
    this.totalPaid = 0.0,
    this.installments = const [],
    this.repayments = const [],
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DebtType type;
  final String personName;
  final String? contactNumber;
  final double principalAmount;
  final InterestType interestType;
  final double interestRate;
  final double interestAmount;
  final double totalRepaymentAmount;
  final DateTime? dueDate;
  final DebtStatus status;
  final String? accountId;
  final String? notes;
  final double totalPaid;
  final List<DebtInstallmentModel> installments;
  final List<DebtRepaymentModel> repayments;
  final DateTime createdAt;

  /// Remaining amount needed to fully settle this debt/loan.
  double get remainingAmount {
    final diff = totalRepaymentAmount - totalPaid;
    return diff > 0 ? diff : 0.0;
  }

  /// Progress ratio clamped from 0.0 to 1.0.
  double get progressRatio {
    if (totalRepaymentAmount <= 0) return 0.0;
    return (totalPaid / totalRepaymentAmount).clamp(0.0, 1.0);
  }

  /// Percentage of total expected repayment paid so far (0.0 to 100.0).
  double get progressPercentage {
    if (totalRepaymentAmount <= 0) return 0.0;
    return ((totalPaid / totalRepaymentAmount) * 100).clamp(0.0, 100.0);
  }

  /// True if debt is marked settled or balance is fully cleared.
  bool get isSettled => status == DebtStatus.settled || remainingAmount <= 0;

  /// True if partially paid but not yet fully settled.
  bool get isPartiallyPaid => totalPaid > 0 && !isSettled;

  /// True if overdue past the due date with a remaining balance.
  bool isOverdue({DateTime? asOfDate}) {
    if (isSettled || dueDate == null) return false;
    final now = asOfDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return target.isBefore(today);
  }

  /// Days remaining until due date (positive if in future, negative if overdue, null if no due date).
  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return target.difference(today).inDays;
  }

  /// Absolute days overdue if past due date.
  int? get daysOverdue {
    final rem = daysRemaining;
    if (rem == null || rem >= 0) return null;
    return rem.abs();
  }

  DebtModel copyWith({
    String? id,
    String? userId,
    DebtType? type,
    String? personName,
    String? contactNumber,
    double? principalAmount,
    InterestType? interestType,
    double? interestRate,
    double? interestAmount,
    double? totalRepaymentAmount,
    DateTime? dueDate,
    DebtStatus? status,
    String? accountId,
    String? notes,
    double? totalPaid,
    List<DebtInstallmentModel>? installments,
    List<DebtRepaymentModel>? repayments,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      contactNumber: contactNumber ?? this.contactNumber,
      principalAmount: principalAmount ?? this.principalAmount,
      interestType: interestType ?? this.interestType,
      interestRate: interestRate ?? this.interestRate,
      interestAmount: interestAmount ?? this.interestAmount,
      totalRepaymentAmount: totalRepaymentAmount ?? this.totalRepaymentAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      totalPaid: totalPaid ?? this.totalPaid,
      installments: installments ?? this.installments,
      repayments: repayments ?? this.repayments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DebtModel.fromMap(
    Map<String, dynamic> map, {
    double totalPaid = 0.0,
    List<DebtInstallmentModel> installments = const [],
    List<DebtRepaymentModel> repayments = const [],
  }) {
    return DebtModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: DebtType.fromString(map['type'] as String? ?? 'YOU_ARE_OWED'),
      personName: map['person_name'] as String,
      contactNumber: map['contact_number'] as String?,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      interestType: InterestType.fromString(map['interest_type'] as String? ?? 'NONE'),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
      interestAmount: (map['interest_amount'] as num?)?.toDouble() ?? 0.0,
      totalRepaymentAmount: (map['total_repayment_amount'] as num).toDouble(),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      status: DebtStatus.fromString(map['status'] as String? ?? 'ACTIVE'),
      accountId: map['account_id'] as String?,
      notes: map['notes'] as String?,
      totalPaid: totalPaid,
      installments: installments,
      repayments: repayments,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.dbValue,
      'person_name': personName,
      'contact_number': contactNumber,
      'principal_amount': principalAmount,
      'interest_type': interestType.dbValue,
      'interest_rate': interestRate,
      'interest_amount': interestAmount,
      'total_repayment_amount': totalRepaymentAmount,
      'due_date': dueDate != null
          ? '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
          : null,
      'status': status.dbValue,
      'account_id': accountId,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          personName == other.personName &&
          principalAmount == other.principalAmount &&
          totalRepaymentAmount == other.totalRepaymentAmount &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      personName.hashCode ^
      principalAmount.hashCode ^
      totalRepaymentAmount.hashCode ^
      status.hashCode;
}
