import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

class VaultItemPinMoreLeading extends StatelessWidget {
  const VaultItemPinMoreLeading({
    super.key,
    required this.isPinned,
    required this.more,
  });

  final bool isPinned;
  final Widget more;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPinned) ...[
          Icon(
            AppIcon.itemPin,
            key: const Key('vault-item-pin-indicator'),
            size: AppSizes.iconSm.s,
            color: context.colors.primary,
          ),
          SizedBox(width: AppSpacing.xs.s),
        ],
        more,
      ],
    );
  }
}

AppHeaderTrailingAction vaultPinHeaderAction({
  required bool isPinned,
  required Color color,
  required VoidCallback onTap,
}) {
  return AppHeaderTrailingAction(
    onTap: onTap,
    child: Icon(
      isPinned ? AppIcon.itemPin : AppIcon.itemUnpin,
      key: const Key('vault-item-pin-toggle'),
      size: AppSizes.iconLg.s,
      color: color,
    ),
  );
}
