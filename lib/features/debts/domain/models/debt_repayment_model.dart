/// Immutable entity representing an individual payment logged against a debt or loan.
class DebtRepaymentModel {
  const DebtRepaymentModel({
    required this.id,
    required this.debtId,
    this.installmentId,
    required this.userId,
    this.accountId,
    required this.amount,
    required this.repaymentDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String debtId;
  final String? installmentId;
  final String userId;
  final String? accountId;
  final double amount;
  final DateTime repaymentDate;
  final String? notes;
  final DateTime createdAt;

  DebtRepaymentModel copyWith({
    String? id,
    String? debtId,
    String? installmentId,
    String? userId,
    String? accountId,
    double? amount,
    DateTime? repaymentDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return DebtRepaymentModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      installmentId: installmentId ?? this.installmentId,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DebtRepaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtRepaymentModel(
      id: map['id'] as String,
      debtId: map['debt_id'] as String,
      installmentId: map['installment_id'] as String?,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      repaymentDate: DateTime.parse((map['repayment_date'] ?? map['payment_date']) as String),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'installment_id': installmentId,
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'repayment_date': '${repaymentDate.year.toString().padLeft(4, '0')}-${repaymentDate.month.toString().padLeft(2, '0')}-${repaymentDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtRepaymentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          debtId == other.debtId &&
          amount == other.amount &&
          repaymentDate == other.repaymentDate;

  @override
  int get hashCode =>
      id.hashCode ^ debtId.hashCode ^ amount.hashCode ^ repaymentDate.hashCode;
}
