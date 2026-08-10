import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/model/category_model.dart';
import 'package:keyva/feature/category/util/category_icons.dart';

class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selectedIconId,
    required this.onSelected,
  });

  final String selectedIconId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      spacing: AppSpacing.sm.s,
      runSpacing: AppSpacing.sm.s,
      children: [
        for (final id in CategoryIconPresets.ids)
          Material(
            color: selectedIconId == id
                ? colors.primary.withValues(alpha: 0.12)
                : colors.input,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: InkWell(
              onTap: () => onSelected(id),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: SizedBox(
                width: 48.s,
                height: 48.s,
                child: CategoryIcons.widgetForId(
                  id,
                  color: selectedIconId == id
                      ? colors.primary
                      : colors.textSecondary,
                  size: AppSizes.iconLg.s,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
