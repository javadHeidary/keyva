import 'dart:typed_data';

import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';

class FakeBackupFileService implements BackupFileService {
  BackupFilePickResult pickResult = const BackupFilePickCancelled();
  BackupFileExportResult exportResult = const BackupFileExportSaved();
  Uint8List? lastExportedBytes;
  String? lastFileName;
  int pickCount = 0;
  int exportCount = 0;

  @override
  Future<BackupFileExportResult> export({
    required Uint8List bytes,
    required String fileName,
  }) async {
    exportCount++;
    lastExportedBytes = bytes;
    lastFileName = fileName;
    return exportResult;
  }

  @override
  Future<BackupFilePickResult> pick() async {
    pickCount++;
    return pickResult;
  }
}
