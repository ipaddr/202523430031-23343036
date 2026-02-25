class AuthUser {
  final String? uid;
  final String? email;
  final bool isEmailVerified;

  const AuthUser({this.uid, this.email, this.isEmailVerified = false});

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, isEmailVerified: $isEmailVerified)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          isEmailVerified == other.isEmailVerified;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode ^ isEmailVerified.hashCode;
}
