import 'dart:typed_data';

import 'package:keyva/feature/backup/model/backup_file_result.dart';

abstract interface class BackupFileService {
  Future<BackupFileExportResult> export({
    required Uint8List bytes,
    required String fileName,
  });

  Future<BackupFilePickResult> pick();
}
