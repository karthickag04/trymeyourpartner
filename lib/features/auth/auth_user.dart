class AppAuthUser {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool emailVerified;

  const AppAuthUser({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.emailVerified = false,
  });
}
