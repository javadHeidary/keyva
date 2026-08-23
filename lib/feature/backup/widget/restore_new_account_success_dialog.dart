import 'package:flutter/material.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

const restoreNewAccountSuccessDescription =
    'حساب با موفقیت ایجاد شد و بازیابی با موفقیت انجام شد.';

Future<void> showRestoreNewAccountSuccessDialog(BuildContext context) {
  return AppDialogWidget.show(
    context,
    key: const Key('backup-restore-success-dialog'),
    buttonKey: const Key('backup-restore-success-got-it'),
    type: AppDialogType.success,
    title: 'بازیابی موفق',
    description: restoreNewAccountSuccessDescription,
    buttonText: 'متوجه شدم',
    barrierDismissible: false,
  );
}
