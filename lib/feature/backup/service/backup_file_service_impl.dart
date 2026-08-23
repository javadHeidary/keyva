import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/backup/model/backup_file_names.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';

class BackupFileServiceImpl implements BackupFileService {
  BackupFileServiceImpl({
    Future<FilePickerResult?> Function()? pickFiles,
    Future<String?> Function({
      required String fileName,
      required Uint8List bytes,
    })?
    saveFile,
    Future<Uint8List> Function(String path)? readPath,
  }) : _pickFiles = pickFiles ?? _defaultPick,
       _saveFile = saveFile ?? _defaultSave,
       _readPath = readPath ?? _defaultReadPath;

  final Future<FilePickerResult?> Function() _pickFiles;
  final Future<String?> Function({
    required String fileName,
    required Uint8List bytes,
  })
  _saveFile;
  final Future<Uint8List> Function(String path) _readPath;

  @override
  Future<BackupFileExportResult> export({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final path = await _saveFile(fileName: fileName, bytes: bytes);
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
      final result = await _pickFiles();
      if (result == null || result.files.isEmpty) {
        return const BackupFilePickCancelled();
      }
      final file = result.files.single;
      final data = file.bytes;
      if (data != null && data.isNotEmpty) {
        return BackupFilePicked(Uint8List.fromList(data));
      }
      final path = file.path;
      if (path == null || path.isEmpty) {
        return const BackupFilePickFailed(InvalidBackupFormatFailure());
      }
      final fromPath = await _readPath(path);
      if (fromPath.isEmpty) {
        return const BackupFilePickFailed(InvalidBackupFormatFailure());
      }
      return BackupFilePicked(fromPath);
    } catch (_) {
      return const BackupFilePickFailed(InvalidBackupFormatFailure());
    }
  }

  static Future<FilePickerResult?> _defaultPick() {
    return FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: false,
    );
  }

  static Future<String?> _defaultSave({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const [BackupFileNames.extension],
    );
  }

  static Future<Uint8List> _defaultReadPath(String path) async {
    return Uint8List.fromList(await File(path).readAsBytes());
  }
}
