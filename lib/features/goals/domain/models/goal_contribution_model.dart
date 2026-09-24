/// Immutable ledger entry representing an allocation (deposit or withdrawal) for a savings goal.
class GoalContributionModel {
  const GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.userId,
    this.accountId,
    required this.amount,
    required this.contributionDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String userId;
  final String? accountId;

  /// Positive for deposit, negative for withdrawal.
  final double amount;
  final DateTime contributionDate;
  final String? notes;
  final DateTime createdAt;

  bool get isDeposit => amount > 0;
  bool get isWithdrawal => amount < 0;
  double get absoluteAmount => amount.abs();

  factory GoalContributionModel.fromMap(Map<String, dynamic> map) {
    return GoalContributionModel(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      contributionDate: DateTime.parse(map['contribution_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'contribution_date': contributionDate.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GoalContributionModel copyWith({
    String? id,
    String? goalId,
    String? userId,
    String? accountId,
    double? amount,
    DateTime? contributionDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return GoalContributionModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      contributionDate: contributionDate ?? this.contributionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContributionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          userId == other.userId &&
          accountId == other.accountId &&
          amount == other.amount &&
          contributionDate == other.contributionDate &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      userId.hashCode ^
      (accountId?.hashCode ?? 0) ^
      amount.hashCode ^
      contributionDate.hashCode ^
      (notes?.hashCode ?? 0);
}
