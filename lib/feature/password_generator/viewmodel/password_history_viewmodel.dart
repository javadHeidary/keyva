import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:keyva/feature/password_generator/util/password_history_date_format.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class PasswordHistoryViewModel extends GetxController {
  PasswordHistoryStore get _store => Get.find<PasswordHistoryStore>();

  List<PasswordHistoryEntry> get entries => _store.entries;

  @override
  void onInit() {
    super.onInit();
    _store.purgeExpired();
  }

  String formatCopiedAt(DateTime dateTime) =>
      formatPasswordHistoryCopiedAt(dateTime);

  void showRetentionInfo(BuildContext context) {
    AppDialogWidget.show(
      context,
      title: 'مدت نگهداری',
      description:
          'رمزهای قبلی فقط به مدت ۷ روز در تاریخچه نگهداری می‌شوند و پس از آن به‌صورت خودکار حذف خواهند شد.',
    );
  }

  void copyPassword(BuildContext context, String password) {
    if (password.isEmpty) return;
    Clipboard.setData(ClipboardData(text: password));
    AppToast.success(context, message: 'رمز عبور کپی شد', title: 'کپی');
  }
}
