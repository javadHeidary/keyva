import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_header_widget.dart';

AppHeaderTrailingAction vaultShareHeaderAction({
  required Color color,
  required VoidCallback onTap,
}) {
  return AppHeaderTrailingAction(
    onTap: onTap,
    child: Icon(
      AppIcon.share,
      key: const Key('vault-item-share'),
      size: AppSizes.iconLg.s,
      color: color,
    ),
  );
}
