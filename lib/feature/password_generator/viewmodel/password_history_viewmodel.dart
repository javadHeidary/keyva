import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class PasswordHistoryViewModel extends GetxController {
  PasswordHistoryStore get _store => Get.find<PasswordHistoryStore>();

  List<PasswordHistoryEntry> get entries => _store.entries;

  String formatCopiedAt(DateTime dateTime) => formatLoginCreatedAt(dateTime);

  void copyPassword(BuildContext context, String password) {
    if (password.isEmpty) return;
    Clipboard.setData(ClipboardData(text: password));
    AppToast.success(context, title: 'رمز عبور کپی شد', message: 'کپی');
  }
}
