/// Pure domain entity representing an authenticated application user.
class UserEntity {
  final String uid;
  final String name;
  final String email;
  final bool hasCompletedSetup;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.hasCompletedSetup = false,
    this.createdAt,
  });

  /// Empty user entity representation for unauthenticated state.
  static const empty = UserEntity(
    uid: '',
    name: '',
    email: '',
    hasCompletedSetup: false,
  );

  bool get isEmpty => uid.isEmpty;
  bool get isNotEmpty => uid.isNotEmpty;
}
