class AccountModel {
  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.isActive,
    this.openingBalance = 0.00,
  });

  final String id;
  final String userId;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isActive;

  /// Opening balance as stored in the DB.
  /// The *current* balance is derived from transactions, not from this field.
  final double openingBalance;

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.00,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'opening_balance': openingBalance,
    };
  }

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
    double? openingBalance,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }
}
