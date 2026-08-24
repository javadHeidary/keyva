import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/util/category_name_validator.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showCreateCategoryDialog({
  required BuildContext context,
  required Iterable<String> existingNames,
  required Future<String?> Function(String name) onCreate,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
    builder: (dialogContext) => _CreateCategoryDialog(
      existingNames: existingNames,
      onCreate: onCreate,
    ),
  );
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog({
    required this.existingNames,
    required this.onCreate,
  });

  final Iterable<String> existingNames;
  final Future<String?> Function(String name) onCreate;

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isCreating) {
      return;
    }
    final name = _nameController.text;
    final validation = CategoryNameValidator.validate(
      name,
      existingNames: widget.existingNames,
    );
    if (validation != null) {
      _formKey.currentState?.validate();
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });
    final persistError = await widget.onCreate(name);
    if (!mounted) {
      return;
    }
    if (persistError == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isCreating = false;
      _error = persistError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.s),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'افزودن دسته‌بندی',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                AppTextFieldWidget(
                  key: const Key('category-inline-name'),
                  controller: _nameController,
                  labelText: 'نام دسته‌بندی',
                  labelAlwaysVisible: true,
                  hintText: 'مثلاً کاری، شخصی',
                  textInputAction: TextInputAction.done,
                  enabled: !_isCreating,
                  autofocus: true,
                  maxLength: CategoryConstants.maxNameLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      CategoryConstants.maxNameLength,
                    ),
                  ],
                  validator: (value) => CategoryNameValidator.validate(
                    value,
                    existingNames: widget.existingNames,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    _error!,
                    key: const Key('category-inline-error'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xl.h),
                AppButtonWidget(
                  key: const Key('category-inline-submit'),
                  title: 'ایجاد',
                  isLoading: _isCreating,
                  onPressed: _submit,
                ),
                SizedBox(height: AppSpacing.sm.h),
                TextButton(
                  key: const Key('category-inline-cancel'),
                  onPressed: _isCreating
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'انصراف',
                    style: AppTypography.button.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
