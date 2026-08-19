import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';

sealed class BackupFileExportResult {
  const BackupFileExportResult();
}

final class BackupFileExportSaved extends BackupFileExportResult {
  const BackupFileExportSaved();
}

final class BackupFileExportCancelled extends BackupFileExportResult {
  const BackupFileExportCancelled();
}

final class BackupFileExportFailed extends BackupFileExportResult {
  const BackupFileExportFailed(this.failure);

  final AppFailure failure;
}

sealed class BackupFilePickResult {
  const BackupFilePickResult();
}

final class BackupFilePicked extends BackupFilePickResult {
  const BackupFilePicked(this.bytes);

  final Uint8List bytes;
}

final class BackupFilePickCancelled extends BackupFilePickResult {
  const BackupFilePickCancelled();
}

final class BackupFilePickFailed extends BackupFilePickResult {
  const BackupFilePickFailed(this.failure);

  final AppFailure failure;
}
