import 'package:flutter/material.dart';

enum VaultItemType { login, bankCard, secureNote }

extension VaultItemTypeX on VaultItemType {
  String get label {
    switch (this) {
      case VaultItemType.login:
        return 'ورودها';
      case VaultItemType.bankCard:
        return 'کارت‌های بانکی';
      case VaultItemType.secureNote:
        return 'یادداشت‌ها';
    }
  }

  IconData get icon {
    switch (this) {
      case VaultItemType.login:
        return Icons.lock_outline_rounded;
      case VaultItemType.bankCard:
        return Icons.credit_card_rounded;
      case VaultItemType.secureNote:
        return Icons.note_alt_outlined;
    }
  }
}

class VaultCategory {
  const VaultCategory({
    required this.id,
    required this.name,
    this.iconId = 'folder',
  });

  final String id;
  final String name;
  final String iconId;
}

class VaultTypeSummary {
  const VaultTypeSummary({required this.type, required this.itemCount});

  final VaultItemType type;
  final int itemCount;
}

class VaultListItem {
  const VaultListItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.categoryId,
  });

  final String id;
  final VaultItemType type;
  final String title;
  final String subtitle;
  final String categoryId;
}
