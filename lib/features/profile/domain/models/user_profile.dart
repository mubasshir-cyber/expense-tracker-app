class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String currencyCode;
  final String currencySymbol;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      currencyCode: map['currency_code'] as String? ?? 'INR',
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
