import 'dart:typed_data';

import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

abstract interface class BackupService {
  Future<Result<Uint8List>> createBackup({required String backupPassword});

  Result<void> validateEnvelope(Uint8List bytes);

  Future<Result<BackupRestorePlan>> decryptBackup({
    required Uint8List bytes,
    required String backupPassword,
  });

  Future<Result<void>> restoreVault(VaultData vault);

  Future<Result<void>> restoreIntoNewAccount({
    required String username,
    required String masterPassword,
    required VaultData vault,
  });
}
