import 'dart:async';
import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
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
  Completer<void>? restoreGate;
  int createCount = 0;
  int validateCount = 0;
  int decryptCount = 0;
  int restoreCount = 0;
  int restoreNewAccountCount = 0;
  String? lastPassword;
  String? lastNewAccountUsername;
  String? lastNewAccountMasterPassword;

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
  }) async {
    decryptCount++;
    lastPassword = backupPassword;
    final failure = decryptFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final current = plan;
    if (current == null) {
      return const FailureResult(WrongBackupPasswordFailure());
    }
    return Success(current);
  }

  @override
  Future<Result<void>> restoreVault(VaultData vault) async {
    restoreCount++;
    restored = vault;
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
  }) async {
    restoreNewAccountCount++;
    lastNewAccountUsername = username;
    lastNewAccountMasterPassword = masterPassword;
    restored = vault;
    final failure = restoreNewAccountFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success<void>(null);
  }
}
