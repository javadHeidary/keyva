abstract final class BackupFileNames {
  static const extension = 'keyva';

  static String suggested({DateTime? now}) {
    final date = now ?? DateTime.now();
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'keyva_backup_$year-$month-$day.$extension';
  }
}
