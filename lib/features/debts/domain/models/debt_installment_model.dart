/// Lifecycle status of an individual installment in a repayment schedule.
enum InstallmentStatus {
  pending('PENDING'),
  partial('PARTIAL'),
  paid('PAID');

  const InstallmentStatus(this.dbValue);

  final String dbValue;

  static InstallmentStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PAID':
        return InstallmentStatus.paid;
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
        return InstallmentStatus.partial;
      case 'PENDING':
      default:
        return InstallmentStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case InstallmentStatus.paid:
        return 'Paid';
      case InstallmentStatus.partial:
        return 'Partial';
      case InstallmentStatus.pending:
        return 'Pending';
    }
  }
}

/// Immutable entity representing a single scheduled payment/installment for a debt or loan.
class DebtInstallmentModel {
  const DebtInstallmentModel({
    required this.id,
    required this.debtId,
    required this.userId,
    required this.installmentNumber,
    required this.dueDate,
    this.principalDue = 0.0,
    this.interestDue = 0.0,
    required this.totalDue,
    this.paidAmount = 0.0,
    this.status = InstallmentStatus.pending,
    this.createdAt,
  });

  final String id;
  final String debtId;
  final String userId;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double totalDue;
  final double paidAmount;
  final InstallmentStatus status;
  final DateTime? createdAt;

  double get remainingAmount {
    final diff = totalDue - paidAmount;
    return diff > 0 ? diff : 0.0;
  }

  double get remainingDue => remainingAmount;

  double get progressRatio {
    if (totalDue <= 0) return 0.0;
    return (paidAmount / totalDue).clamp(0.0, 1.0);
  }

  bool get isPaid => status == InstallmentStatus.paid || paidAmount >= totalDue;
  bool get isPartial => status == InstallmentStatus.partial || (paidAmount > 0 && paidAmount < totalDue);
  bool get isPending => status == InstallmentStatus.pending && paidAmount == 0;

  bool isOverdue({DateTime? asOfDate}) {
    if (isPaid) return false;
    final now = asOfDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.isBefore(today);
  }

  DebtInstallmentModel copyWith({
    String? id,
    String? debtId,
    String? userId,
    int? installmentNumber,
    DateTime? dueDate,
    double? principalDue,
    double? interestDue,
    double? totalDue,
    double? paidAmount,
    InstallmentStatus? status,
    DateTime? createdAt,
  }) {
    return DebtInstallmentModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      userId: userId ?? this.userId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      principalDue: principalDue ?? this.principalDue,
      interestDue: interestDue ?? this.interestDue,
      totalDue: totalDue ?? this.totalDue,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DebtInstallmentModel.fromMap(Map<String, dynamic> map) {
    return DebtInstallmentModel(
      id: map['id'] as String,
      debtId: map['debt_id'] as String,
      userId: map['user_id'] as String,
      installmentNumber: (map['installment_number'] as num).toInt(),
      dueDate: DateTime.parse(map['due_date'] as String),
      principalDue: (map['principal_due'] as num?)?.toDouble() ?? 0.0,
      interestDue: (map['interest_due'] as num?)?.toDouble() ?? 0.0,
      totalDue: (map['total_due'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: InstallmentStatus.fromString(map['status'] as String? ?? 'PENDING'),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'debt_id': debtId,
      'user_id': userId,
      'installment_number': installmentNumber,
      'due_date': '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      'principal_due': principalDue,
      'interest_due': interestDue,
      'total_due': totalDue,
      'paid_amount': paidAmount,
      'status': status.dbValue,
    };
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtInstallmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          debtId == other.debtId &&
          installmentNumber == other.installmentNumber &&
          totalDue == other.totalDue &&
          paidAmount == other.paidAmount &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      debtId.hashCode ^
      installmentNumber.hashCode ^
      totalDue.hashCode ^
      paidAmount.hashCode ^
      status.hashCode;
}
