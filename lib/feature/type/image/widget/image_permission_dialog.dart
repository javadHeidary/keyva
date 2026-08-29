import 'package:flutter/material.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showImagePermissionDeniedDialog(
  BuildContext context, {
  required bool isCamera,
  bool forSave = false,
}) {
  return AppDialogWidget.show(
    context,
    type: AppDialogType.warning,
    title: isCamera ? 'دسترسی دوربین' : 'دسترسی گالری',
    description: isCamera
        ? 'دسترسی به دوربین داده نشده است. می‌توانید از تنظیمات برنامه آن را فعال کنید.'
        : forSave
        ? 'برای ذخیره تصویر در گالری، دسترسی لازم است. می‌توانید از تنظیمات برنامه آن را فعال کنید.'
        : 'دسترسی به گالری داده نشده است. می‌توانید از تنظیمات برنامه آن را فعال کنید.',
    buttonText: 'باز کردن تنظیمات',
    onConfirm: openAppSettings,
  );
}
