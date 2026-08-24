import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/widget/create_category_dialog.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/shared/widget/app_dropdown_widget.dart';

class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.selectedId,
    required this.categories,
    required this.onChanged,
    required this.onCreate,
    this.fillColor,
  });

  final String? selectedId;
  final List<VaultCategory> categories;
  final ValueChanged<String?> onChanged;
  final Future<String?> Function(String name) onCreate;
  final Color? fillColor;

  Future<void> _openCreateDialog(BuildContext context) {
    return showCreateCategoryDialog(
      context: context,
      existingNames: categories.map((category) => category.name),
      onCreate: onCreate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      const AppDropdownItem<String?>(
        value: null,
        label: 'بدون دسته‌بندی',
        icon: Icon(Icons.label_off_outlined),
      ),
      ...categories.map(
        (category) => AppDropdownItem<String?>(
          value: category.id,
          label: category.name,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdownWidget<String?>(
          value: selectedId,
          hint: 'بدون دسته‌بندی',
          items: items,
          labelText: 'دسته‌بندی',
          labelAlwaysVisible: true,
          useOutlinedStyle: true,
          fillColor: fillColor,
          leadingIcon: Icon(
            Icons.folder_outlined,
            size: AppSizes.iconMd.s,
            color: colors.textSecondary,
          ),
          onChanged: onChanged,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('category-inline-add'),
            onPressed: () => _openCreateDialog(context),
            icon: Icon(
              Icons.add_rounded,
              size: AppSizes.iconMd.s,
              color: colors.primary,
            ),
            label: Text(
              'افزودن دسته‌بندی',
              style: TextStyle(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
