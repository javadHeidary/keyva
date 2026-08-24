import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/security/backup_password_policy.dart';
import 'package:keyva/core/security/master_password_policy.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/backup/widget/restore_new_account_success_dialog.dart';
import 'package:keyva/feature/search/viewmodel/search_viewmodel.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

enum RestoreMode { replaceExisting, createAccount }

class RestoreViewModel extends GetxController {
  RestoreViewModel({
    required BackupService backup,
    required BackupFileService files,
    required SessionService session,
    this.mode = RestoreMode.replaceExisting,
  }) : _backup = backup,
       _files = files,
       _session = session;

  final BackupService _backup;
  final BackupFileService _files;
  final SessionService _session;
  final RestoreMode mode;

  final isBusy = false.obs;
  final errorMessage = ''.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final dialogCountdown = 3.obs;
  final canConfirmDialog = false.obs;
  final progress = Rxn<RestoreProgress>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final setupFormKey = GlobalKey<FormState>();

  Uint8List? _selectedBytes;
  VaultData? _pendingVault;
  BackupPreview? _pendingPreview;
  bool _newAccountRestoreSucceeded = false;
  bool _successDialogShown = false;

  bool get createsNewAccount => mode == RestoreMode.createAccount;

  bool get hasPendingRestore => _pendingVault != null;

  bool get didCompleteNewAccountRestore => _newAccountRestoreSucceeded;

  BackupPreview? get pendingPreview => _pendingPreview;

  bool get _canOperateWithoutSession => createsNewAccount;

  bool get _sessionReady => _session.isAuthenticated || _canOperateWithoutSession;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void startWarningDialogCountdown() {
    dialogCountdown.value = 3;
    canConfirmDialog.value = false;
    _runCountdown();
  }

  Future<void> _runCountdown() async {
    while (dialogCountdown.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (isClosed) return;
      dialogCountdown.value--;
    }
    canConfirmDialog.value = true;
  }

  Future<bool> pickBackup(BuildContext context) async {
    if (isBusy.value) {
      return false;
    }
    if (!_sessionReady) {
      AppToast.error(
        context,
        title: 'بازیابی پشتیبان',
        message: vaultUserMessage(const AuthenticationFailure().message),
      );
      return false;
    }

    isBusy.value = true;
    try {
      _selectedBytes = null;
      _pendingVault = null;
      _pendingPreview = null;
      final picked = await _files.pick();
      if (!context.mounted) {
        return false;
      }
      switch (picked) {
        case BackupFilePickCancelled():
          return false;
        case BackupFilePickFailed(:final failure):
          AppToast.error(
            context,
            title: 'بازیابی پشتیبان',
            message: vaultUserMessage(failure.message),
          );
          return false;
        case BackupFilePicked(:final bytes):
          final validated = _backup.validateEnvelope(bytes);
          if (validated is FailureResult<void>) {
            AppToast.error(
              context,
              title: 'بازیابی پشتیبان',
              message: vaultUserMessage(validated.failure.message),
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
    if (!_sessionReady) {
      AppToast.error(
        context,
        title: 'بازیابی پشتیبان',
        message: vaultUserMessage(const AuthenticationFailure().message),
      );
      _clearPending();
      return null;
    }
    final policyError = BackupPasswordPolicy.fieldError(password);
    if (policyError != null) {
      AppToast.error(context, title: 'بازیابی پشتیبان', message: policyError);
      return null;
    }

    isBusy.value = true;
    try {
      final decrypted = await _backup.decryptBackup(
        bytes: bytes,
        backupPassword: password,
        onProgress: _onProgress,
      );
      if (!context.mounted) {
        return null;
      }
      if (!_sessionReady) {
        _clearPending();
        AppToast.error(
          context,
          title: 'بازیابی پشتیبان',
          message: vaultUserMessage(const AuthenticationFailure().message),
        );
        return null;
      }
      if (decrypted is FailureResult<BackupRestorePlan>) {
        AppToast.error(
          context,
          title: 'بازیابی پشتیبان',
          message: vaultUserMessage(decrypted.failure.message),
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
    if (isBusy.value || createsNewAccount) {
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
        title: 'بازیابی پشتیبان',
        message: vaultUserMessage(const AuthenticationFailure().message),
      );
      return;
    }

    isBusy.value = true;
    try {
      final restored = await _backup.restoreVault(
        vault,
        onProgress: _onProgress,
      );
      if (!context.mounted || !_session.isAuthenticated) {
        _clearPending();
        return;
      }
      if (restored is FailureResult<void>) {
        AppToast.error(
          context,
          title: 'بازیابی پشتیبان',
          message: vaultUserMessage(restored.failure.message),
        );
        return;
      }
      _onProgress(RestoreProgress.replaceRefreshing());
      _clearPending();
      await _refreshVaultUi();
      if (!context.mounted || !_session.isAuthenticated) {
        return;
      }
      _onProgress(RestoreProgress.commitCompleted());
      AppToast.success(
        context,
        title: 'بازیابی پشتیبان',
        message: 'اطلاعات Vault جایگزین شد',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> completeNewAccountRestore(BuildContext context) async {
    if (isBusy.value || !createsNewAccount) {
      return;
    }
    final vault = _pendingVault;
    if (vault == null) {
      return;
    }
    errorMessage.value = '';
    final form = setupFormKey.currentState;
    if (form != null && !form.validate()) {
      return;
    }
    final usernameError = restoreUsernameError(usernameController.text);
    if (usernameError != null) {
      errorMessage.value = usernameError;
      return;
    }
    final passwordError = restoreMasterPasswordError(passwordController.text);
    if (passwordError != null) {
      errorMessage.value = passwordError;
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      errorMessage.value = 'تکرار رمز عبور یکسان نیست';
      return;
    }

    isBusy.value = true;
    try {
      final restored = await _backup.restoreIntoNewAccount(
        username: usernameController.text.trim(),
        masterPassword: passwordController.text,
        vault: vault,
        onProgress: _onProgress,
      );
      if (restored is FailureResult<void>) {
        if (!context.mounted) {
          return;
        }
        errorMessage.value = vaultUserMessage(restored.failure.message);
        return;
      }
      _clearPending();
      _newAccountRestoreSucceeded = true;
    } finally {
      passwordController.clear();
      confirmPasswordController.clear();
      isBusy.value = false;
    }
  }

  void cancelRestore() {
    _clearPending();
  }

  Future<void> presentNewAccountRestoreSuccess(BuildContext context) async {
    if (!createsNewAccount ||
        !_newAccountRestoreSucceeded ||
        _successDialogShown ||
        isClosed) {
      return;
    }
    _successDialogShown = true;
    if (context.mounted) {
      await showRestoreNewAccountSuccessDialog(context);
    }
    Get.offAllNamed(AppRoutes.shell);
  }

  void clearProgress() {
    progress.value = null;
  }

  void _onProgress(RestoreProgress value) {
    if (isClosed) {
      return;
    }
    progress.value = value;
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
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    clearProgress();
    _clearPending();
    super.onClose();
  }
}

String? restoreUsernameError(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) {
    return 'نام کاربری الزامی است';
  }
  if (username.length < 3) {
    return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
  }
  return null;
}

String? restoreMasterPasswordError(String? value) {
  return MasterPasswordPolicy.fieldError(value);
}
