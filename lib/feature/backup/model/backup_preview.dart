import 'dart:typed_data';

import 'package:keyva/feature/vault/model/vault_data.dart';

class BackupPreview {
  const BackupPreview({
    required this.loginCount,
    required this.bankCardCount,
    required this.secureNoteCount,
    required this.imageFolderCount,
    required this.imageCount,
    required this.categoryCount,
  });

  factory BackupPreview.fromVault(VaultData vault) {
    return BackupPreview(
      loginCount: vault.logins.length,
      bankCardCount: vault.bankCards.length,
      secureNoteCount: vault.secureNotes.length,
      imageFolderCount: vault.imageFolders.length,
      imageCount: vault.images.length,
      categoryCount: vault.categories.length,
    );
  }

  final int loginCount;
  final int bankCardCount;
  final int secureNoteCount;
  final int imageFolderCount;
  final int imageCount;
  final int categoryCount;

  List<String> get countLines => [
    'اکانت: $loginCount',
    'کارت بانکی: $bankCardCount',
    'یادداشت امن: $secureNoteCount',
    'پوشه تصویر: $imageFolderCount',
    'تصویر: $imageCount',
    'دسته‌بندی: $categoryCount',
  ];

  String get confirmationDescription {
    return '${countLines.join('\n')}\n\n'
        'این کار اطلاعات فعلی Vault را با اطلاعات فایل پشتیبان جایگزین '
        'می‌کند.\n\nقبل از ادامه مطمئن شوید که از اطلاعات فعلی نسخه '
        'پشتیبان دارید.';
  }

  String get newAccountDescription {
    return '${countLines.join('\n')}\n\n'
        'یک حساب جدید از روی این پشتیبان ساخته می‌شود.\n'
        'رمز فایل پشتیبان، رمز اصلی حساب نخواهد شد.';
  }
}

class BackupRestorePlan {
  const BackupRestorePlan({
    required this.vault,
    required this.preview,
    this.imageBlobs = const {},
  });

  final VaultData vault;
  final BackupPreview preview;
  final Map<String, Uint8List> imageBlobs;
}
