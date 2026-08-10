import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';

class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 45.s,
        height: 45.s,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Center(
          child: Icon(icon, size: AppSizes.iconLg.s, color: colors.onPrimary),
        ),
      ),
    );
  }
}
