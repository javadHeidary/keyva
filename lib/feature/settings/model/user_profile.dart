class UserProfile {
  const UserProfile({
    required this.name,
    this.avatarId = UserProfileAvatars.defaultId,
  });

  final String name;
  final String avatarId;

  static const defaultName = 'علی رضایی';

  UserProfile copyWith({String? name, String? avatarId}) {
    return UserProfile(
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}

class UserProfileAvatars {
  UserProfileAvatars._();

  static const defaultId = 'person';

  static const presets = <AvatarPreset>[
    AvatarPreset(id: 'person', iconCodePoint: 0xe7fd),
    AvatarPreset(id: 'shield', iconCodePoint: 0xe9e0),
    AvatarPreset(id: 'key', iconCodePoint: 0xe73c),
    AvatarPreset(id: 'lock', iconCodePoint: 0xe897),
    AvatarPreset(id: 'vault', iconCodePoint: 0xe2c7),
    AvatarPreset(id: 'star', iconCodePoint: 0xe838),
  ];

  static AvatarPreset? findById(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

class AvatarPreset {
  const AvatarPreset({required this.id, required this.iconCodePoint});

  final String id;
  final int iconCodePoint;
}
