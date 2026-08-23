import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/backup/model/backup_file_result.dart';
import 'package:keyva/feature/backup/service/backup_file_service_impl.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_backup_files_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('pick uses in-memory bytes when the picker provides them', () async {
    final service = BackupFileServiceImpl(
      pickFiles: () async => FilePickerResult([
        PlatformFile(
          name: 'backup.keyva',
          size: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ]),
    );

    final picked = await service.pick();
    expect(picked, isA<BackupFilePicked>());
    expect((picked as BackupFilePicked).bytes, [1, 2, 3]);
  });

  test('pick falls back to the file path when picker bytes are missing', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}backup.keyva');
    await file.writeAsBytes(const [9, 8, 7, 6]);

    final service = BackupFileServiceImpl(
      pickFiles: () async => FilePickerResult([
        PlatformFile(name: 'backup.keyva', size: 4, path: file.path),
      ]),
    );

    final picked = await service.pick();
    expect(picked, isA<BackupFilePicked>());
    expect((picked as BackupFilePicked).bytes, [9, 8, 7, 6]);
  });

  test('pick maps an unreadable path to an invalid backup file', () async {
    final service = BackupFileServiceImpl(
      pickFiles: () async => FilePickerResult([
        PlatformFile(
          name: 'backup.keyva',
          size: 1,
          path: '${tempDir.path}${Platform.pathSeparator}missing.keyva',
        ),
      ]),
    );

    final picked = await service.pick();
    expect(picked, isA<BackupFilePickFailed>());
    expect(
      (picked as BackupFilePickFailed).failure,
      isA<InvalidBackupFormatFailure>(),
    );
  });

  test('pick treats a dismissed picker as cancellation', () async {
    final service = BackupFileServiceImpl(pickFiles: () async => null);
    expect(await service.pick(), isA<BackupFilePickCancelled>());
  });
}
