class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.emailConfirmedAt,
  });

  final String id;
  final String email;
  final DateTime? emailConfirmedAt;

  bool get isEmailConfirmed => emailConfirmedAt != null;

  @override
  String toString() {
    return 'AuthUser('
        'id: $id, '
        'email: $email, '
        'emailConfirmedAt: $emailConfirmedAt'
        ')';
  }
}
