import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class RestoreViewModel extends GetxController {
  RestoreViewModel({
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

  Uint8List? _selectedBytes;
  VaultData? _pendingVault;
  BackupPreview? _pendingPreview;

  bool get hasPendingRestore => _pendingVault != null;

  BackupPreview? get pendingPreview => _pendingPreview;

  Future<bool> pickBackup(BuildContext context) async {
    if (isBusy.value) {
      return false;
    }
    if (!_session.isAuthenticated) {
      AppToast.error(
        context,
        title: vaultUserMessage(const AuthenticationFailure().message),
      );
      return false;
    }

    isBusy.value = true;
    try {
      _selectedBytes = null;
      _pendingVault = null;
      final picked = await _files.pick();
      if (!context.mounted) {
        return false;
      }
      switch (picked) {
        case BackupFilePickCancelled():
          return false;
        case BackupFilePickFailed(:final failure):
          AppToast.error(context, title: vaultUserMessage(failure.message));
          return false;
        case BackupFilePicked(:final bytes):
          final validated = _backup.validateEnvelope(bytes);
          if (validated is FailureResult<void>) {
            AppToast.error(
              context,
              title: vaultUserMessage(validated.failure.message),
            );
            return false;
          }
          _selectedBytes = bytes;
          return true;
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<BackupPreview?> decryptSelectedBackup({
    required String password,
    required BuildContext context,
  }) async {
    if (isBusy.value) {
      return null;
    }
    final bytes = _selectedBytes;
    if (bytes == null) {
      return null;
    }
    if (!_session.isAuthenticated) {
      AppToast.error(
        context,
        title: vaultUserMessage(const AuthenticationFailure().message),
      );
      _clearPending();
      return null;
    }
    final policyError = BackupPasswordPolicy.fieldError(password);
    if (policyError != null) {
      AppToast.error(context, title: policyError);
      return null;
    }

    isBusy.value = true;
    try {
      final decrypted = await _backup.decryptBackup(
        bytes: bytes,
        backupPassword: password,
      );
      if (!context.mounted) {
        return null;
      }
      if (!_session.isAuthenticated) {
        _clearPending();
        AppToast.error(
          context,
          title: vaultUserMessage(const AuthenticationFailure().message),
        );
        return null;
      }
      if (decrypted is FailureResult<BackupRestorePlan>) {
        AppToast.error(
          context,
          title: vaultUserMessage(decrypted.failure.message),
        );
        return null;
      }
      final plan = (decrypted as Success<BackupRestorePlan>).data;
      _pendingVault = plan.vault;
      _pendingPreview = plan.preview;
      return plan.preview;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> confirmRestore(BuildContext context) async {
    if (isBusy.value) {
      return;
    }
    final vault = _pendingVault;
    if (vault == null) {
      return;
    }
    if (!_session.isAuthenticated) {
      _clearPending();
      AppToast.error(
        context,
        title: vaultUserMessage(const AuthenticationFailure().message),
      );
      return;
    }

    isBusy.value = true;
    try {
      final restored = await _backup.restoreVault(vault);
      if (!context.mounted || !_session.isAuthenticated) {
        _clearPending();
        return;
      }
      if (restored is FailureResult<void>) {
        AppToast.error(
          context,
          title: vaultUserMessage(restored.failure.message),
        );
        return;
      }
      _clearPending();
      await _refreshVaultUi();
      if (!context.mounted || !_session.isAuthenticated) {
        return;
      }
      AppToast.success(
        context,
        title: 'بازیابی پشتیبان',
        message: 'اطلاعات Vault جایگزین شد',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void cancelRestore() {
    _clearPending();
  }

  Future<void> _refreshVaultUi() async {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      return;
    }
    final vault = Get.find<VaultHomeViewModel>();
    vault.searchItems('');
    await vault.refreshVault();
    if (Get.isRegistered<SearchViewModel>()) {
      Get.find<SearchViewModel>().reloadFromVault();
    }
  }

  void _clearPending() {
    _selectedBytes = null;
    _pendingVault = null;
    _pendingPreview = null;
  }

  @override
  void onClose() {
    _clearPending();
    super.onClose();
  }
}
