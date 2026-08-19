import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/backup/model/backup_file_names.dart';

void main() {
  test('builds a date-only keyva filename', () {
    expect(
      BackupFileNames.suggested(now: DateTime(2026, 8, 19)),
      'keyva_backup_2026-08-19.keyva',
    );
  });
}
