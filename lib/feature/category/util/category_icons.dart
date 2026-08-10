import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static IconData iconForId(String id) {
    return switch (id) {
      'work' => Icons.work_outline_rounded,
      'person' => Icons.person_outline_rounded,
      'finance' => Icons.account_balance_wallet_outlined,
      'business' => Icons.business_center_outlined,
      'lock' => Icons.lock_outline_rounded,
      'star' => Icons.star_outline_rounded,
      _ => Icons.folder_outlined,
    };
  }

  static Widget widgetForId(String iconId, {required Color color, double size = 28}) {
    return Icon(iconForId(iconId), size: size, color: color);
  }
}
