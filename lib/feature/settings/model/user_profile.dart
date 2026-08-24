class UserProfile {
  const UserProfile({required this.name});

  final String name;

  static const defaultName = 'علی رضایی';

  UserProfile copyWith({String? name}) {
    return UserProfile(name: name ?? this.name);
  }
}
