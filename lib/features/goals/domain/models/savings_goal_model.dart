/// Immutable entity representing a financial savings goal.
class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.icon,
    this.color,
    this.accountId,
    this.categoryId,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final double targetAmount;

  /// Current saved balance (derived from contribution ledger).
  final double currentAmount;

  final DateTime? targetDate;
  final String? icon;
  final String? color;
  final String? accountId;
  final String? categoryId;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  /// Percentage of target amount saved (0.0 to 100.0).
  double get savedPercentage {
    if (targetAmount <= 0) return 0.0;
    return ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0);
  }

  /// Clamped ratio (0.0 to 1.0) for progress indicators.
  double get progressRatio => (savedPercentage / 100).clamp(0.0, 1.0);

  /// Remaining amount needed to hit target.
  double get remainingAmount {
    final diff = targetAmount - currentAmount;
    return diff > 0 ? diff : 0.0;
  }

  /// True if current saved balance meets or exceeds target amount.
  bool get isCompleted => currentAmount >= targetAmount;
  bool get isReached => isCompleted;

  /// Days remaining until target date (null if no deadline set).
  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    return target.difference(today).inDays;
  }

  factory SavingsGoalModel.fromMap(
    Map<String, dynamic> map, {
    double currentAmount = 0.0,
  }) {
    return SavingsGoalModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] != null)
          ? (map['current_amount'] as num).toDouble()
          : currentAmount,
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      accountId: map['account_id'] as String?,
      categoryId: map['category_id'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'icon': icon,
      'color': color,
      'account_id': accountId,
      'category_id': categoryId,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? icon,
    String? color,
    String? accountId,
    bool clearAccountId = false,
    String? categoryId,
    bool clearCategoryId = false,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          targetDate == other.targetDate &&
          icon == other.icon &&
          color == other.color &&
          accountId == other.accountId &&
          categoryId == other.categoryId &&
          isActive == other.isActive &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      targetAmount.hashCode ^
      currentAmount.hashCode ^
      (targetDate?.hashCode ?? 0) ^
      (icon?.hashCode ?? 0) ^
      (color?.hashCode ?? 0) ^
      (accountId?.hashCode ?? 0) ^
      (categoryId?.hashCode ?? 0) ^
      isActive.hashCode ^
      (notes?.hashCode ?? 0);
}
