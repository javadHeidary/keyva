import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class VaultItemDetailsLeading extends StatelessWidget {
  const VaultItemDetailsLeading({
    super.key,
    required this.openedAfterCreate,
  });

  final bool openedAfterCreate;

  @override
  Widget build(BuildContext context) {
    return Icon(
      key: openedAfterCreate
          ? const Key('vault-item-details-confirm')
          : const Key('vault-item-details-back'),
      openedAfterCreate ? AppIcon.check : AppIcon.arrowBack,
      size: AppSizes.iconLg.s,
      color: context.colors.textPrimary,
    );
  }
}
