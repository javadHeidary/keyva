import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/backup/model/backup_file_names.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';

class BackupFileServiceImpl implements BackupFileService {
  @override
  Future<BackupFileExportResult> export({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const [BackupFileNames.extension],
      );
      if (path == null) {
        return const BackupFileExportCancelled();
      }
      return const BackupFileExportSaved();
    } catch (_) {
      return const BackupFileExportFailed(BackupExportFailure());
    }
  }

  @override
  Future<BackupFilePickResult> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [BackupFileNames.extension],
        withData: true,
        allowMultiple: false,
      );
      if (result == null) {
        return const BackupFilePickCancelled();
      }
      final data = result.files.single.bytes;
      if (data == null || data.isEmpty) {
        return const BackupFilePickFailed(InvalidBackupFormatFailure());
      }
      return BackupFilePicked(Uint8List.fromList(data));
    } catch (_) {
      return const BackupFilePickFailed(InvalidBackupFormatFailure());
    }
  }
}
