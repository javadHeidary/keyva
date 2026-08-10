import 'package:flutter/material.dart';

class SettingsAvatarIcons {
  SettingsAvatarIcons._();

  static IconData iconForId(String id) {
    return switch (id) {
      'shield' => Icons.shield_rounded,
      'key' => Icons.vpn_key_rounded,
      'lock' => Icons.lock_rounded,
      'vault' => Icons.account_balance_wallet_rounded,
      'star' => Icons.star_rounded,
      _ => Icons.person_rounded,
    };
  }

  static Widget avatarWidget(String avatarId, {required Color color, double size = 28}) {
    return Icon(
      iconForId(avatarId),
      size: size,
      color: color,
    );
  }
}
