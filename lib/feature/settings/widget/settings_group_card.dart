import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: context.shadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SettingsGroupDivider(),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsGroupDivider extends StatelessWidget {
  const SettingsGroupDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.w,
      child: Divider(height: 1, thickness: 2, color: context.colors.divider),
    );
  }
}
