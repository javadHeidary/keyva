import 'dart:async';
import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

class FakeBackupService implements BackupService {
  Uint8List? createdBytes;
  AppFailure? createFailure;
  AppFailure? validateFailure;
  AppFailure? decryptFailure;
  AppFailure? restoreFailure;
  AppFailure? restoreNewAccountFailure;
  BackupRestorePlan? plan;
  VaultData? restored;
  Completer<void>? decryptGate;
  Completer<void>? restoreGate;
  Completer<void>? restoreNewAccountGate;
  int createCount = 0;
  int validateCount = 0;
  int decryptCount = 0;
  int restoreCount = 0;
  int restoreNewAccountCount = 0;
  String? lastPassword;
  String? lastNewAccountUsername;
  String? lastNewAccountMasterPassword;
  final decryptProgress = <RestoreProgress>[];
  final restoreProgress = <RestoreProgress>[];
  final restoreNewAccountProgress = <RestoreProgress>[];

  @override
  Future<Result<Uint8List>> createBackup({required String backupPassword}) async {
    createCount++;
    lastPassword = backupPassword;
    final failure = createFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return Success(createdBytes ?? Uint8List.fromList([1, 2, 3]));
  }

  @override
  Result<void> validateEnvelope(Uint8List bytes) {
    validateCount++;
    final failure = validateFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<BackupRestorePlan>> decryptBackup({
    required Uint8List bytes,
    required String backupPassword,
    RestoreProgressCallback? onProgress,
  }) async {
    decryptCount++;
    lastPassword = backupPassword;
    _emitDecrypt(onProgress, RestoreProgress.decryptStarting());
    _emitDecrypt(onProgress, RestoreProgress.decryptValidating());
    _emitDecrypt(onProgress, RestoreProgress.decryptDerivingKey());
    final gate = decryptGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = decryptFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final current = plan;
    if (current == null) {
      return const FailureResult(WrongBackupPasswordFailure());
    }
    _emitDecrypt(onProgress, RestoreProgress.decryptDecrypting());
    _emitDecrypt(onProgress, RestoreProgress.decryptDeserializing());
    _emitDecrypt(onProgress, RestoreProgress.decryptCompleted());
    return Success(current);
  }

  @override
  Future<Result<void>> restoreVault(
    VaultData vault, {
    Map<String, Uint8List> imageBlobs = const {},
    RestoreProgressCallback? onProgress,
  }) async {
    restoreCount++;
    restored = vault;
    _emitRestore(onProgress, RestoreProgress.replacePersisting());
    final gate = restoreGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = restoreFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restoreIntoNewAccount({
    required String username,
    required String masterPassword,
    required VaultData vault,
    Map<String, Uint8List> imageBlobs = const {},
    RestoreProgressCallback? onProgress,
  }) async {
    restoreNewAccountCount++;
    lastNewAccountUsername = username;
    lastNewAccountMasterPassword = masterPassword;
    restored = vault;
    _emitNewAccount(onProgress, RestoreProgress.newAccountPreparing());
    _emitNewAccount(onProgress, RestoreProgress.newAccountCreating());
    _emitNewAccount(onProgress, RestoreProgress.newAccountUnlocking());
    _emitNewAccount(onProgress, RestoreProgress.newAccountPersisting());
    final gate = restoreNewAccountGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = restoreNewAccountFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    _emitNewAccount(onProgress, RestoreProgress.commitCompleted());
    return const Success<void>(null);
  }

  void _emitDecrypt(
    RestoreProgressCallback? onProgress,
    RestoreProgress progress,
  ) {
    decryptProgress.add(progress);
    onProgress?.call(progress);
  }

  void _emitRestore(
    RestoreProgressCallback? onProgress,
    RestoreProgress progress,
  ) {
    restoreProgress.add(progress);
    onProgress?.call(progress);
  }

  void _emitNewAccount(
    RestoreProgressCallback? onProgress,
    RestoreProgress progress,
  ) {
    restoreNewAccountProgress.add(progress);
    onProgress?.call(progress);
  }
}
