import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/backup/model/backup_file_names.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class BackupViewModel extends GetxController {
  BackupViewModel({
    required BackupService backup,
    required BackupFileService files,
    required SessionService session,
  }) : _backup = backup,
       _files = files,
       _session = session;

  final BackupService _backup;
  final BackupFileService _files;
  final SessionService _session;

  final isBusy = false.obs;

  Future<void> createBackup({
    required String password,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (isBusy.value) {
      return;
    }
    if (!_session.isAuthenticated) {
      AppToast.error(
        context,
        title: 'پشتیبان‌گیری',
        message: vaultUserMessage(const AuthenticationFailure().message),
      );
      return;
    }
    final policyError = BackupPasswordPolicy.fieldError(password);
    if (policyError != null) {
      AppToast.error(context, title: 'پشتیبان‌گیری', message: policyError);
      return;
    }
    if (password != confirmPassword) {
      AppToast.error(
        context,
        title: 'پشتیبان‌گیری',
        message: 'تکرار رمز با رمز پشتیبان یکسان نیست',
      );
      return;
    }

    isBusy.value = true;
    try {
      final created = await _backup.createBackup(backupPassword: password);
      if (!context.mounted) {
        return;
      }
      if (!_session.isAuthenticated) {
        AppToast.error(
          context,
          title: 'پشتیبان‌گیری',
          message: vaultUserMessage(const AuthenticationFailure().message),
        );
        return;
      }
      if (created is FailureResult<Uint8List>) {
        AppToast.error(
          context,
          title: 'پشتیبان‌گیری',
          message: vaultUserMessage(created.failure.message),
        );
        return;
      }

      final exported = await _files.export(
        bytes: (created as Success<Uint8List>).data,
        fileName: BackupFileNames.suggested(),
      );
      if (!context.mounted) {
        return;
      }
      switch (exported) {
        case BackupFileExportCancelled():
          return;
        case BackupFileExportFailed(:final failure):
          AppToast.error(
            context,
            title: 'پشتیبان‌گیری',
            message: vaultUserMessage(failure.message),
          );
          return;
        case BackupFileExportSaved():
          AppToast.success(
            context,
            title: 'پشتیبان‌گیری',
            message: 'فایل پشتیبان ذخیره شد',
          );
          Get.back();
      }
    } finally {
      isBusy.value = false;
    }
  }
}
