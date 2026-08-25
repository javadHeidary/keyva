import 'package:flutter/material.dart';
import 'package:keyva/shared/icons/app_icons.dart';

enum VaultItemType { login, bankCard, secureNote, image }

extension VaultItemTypeX on VaultItemType {
  String get label {
    switch (this) {
      case VaultItemType.login:
        return 'اکانت‌ها';
      case VaultItemType.bankCard:
        return 'کارت‌های بانکی';
      case VaultItemType.secureNote:
        return 'یادداشت‌ها';
      case VaultItemType.image:
        return 'تصاویر';
    }
  }

  String get listTitle {
    switch (this) {
      case VaultItemType.login:
        return 'لیست اکانت‌ها';
      case VaultItemType.bankCard:
      case VaultItemType.secureNote:
      case VaultItemType.image:
        return label;
    }
  }

  IconData get icon {
    switch (this) {
      case VaultItemType.login:
        return AppIcon.lock;
      case VaultItemType.bankCard:
        return AppIcon.creditCard;
      case VaultItemType.secureNote:
        return AppIcon.stickyNote;
      case VaultItemType.image:
        return AppIcon.images;
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
    this.isPinned = false,
  });

  final String id;
  final VaultItemType type;
  final String title;
  final String subtitle;
  final String categoryId;
  final bool isPinned;
}
