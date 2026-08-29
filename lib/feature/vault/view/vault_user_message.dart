String vaultUserMessage(String? errorMessage) {
  if (errorMessage == null || errorMessage.trim().isEmpty) {
    return 'خطایی رخ داد. لطفاً دوباره تلاش کنید.';
  }

  switch (errorMessage) {
    case 'Unable to unlock your vault.':
      return 'باز کردن گاوصندوق ممکن نشد.';
    case 'Biometric authentication is unavailable.':
      return 'ورود با اثرانگشت روی این دستگاه در دسترس نیست.';
    case 'Biometric authentication failed.':
      return 'ورود با اثرانگشت ناموفق بود.';
    case 'Biometric unlock is not set up for this account.':
      return 'ورود با اثرانگشت برای این حساب تنظیم نشده است.';
    case 'Biometric unlock is locked. Use your master password.':
      return 'محدودیت تلاش ورود با اثرانگشت تمام شده است. اکنون فقط با رمز اصلی می‌توانید وارد شوید.';
    case 'Master password unlock is locked. Try again after the lockout ends.':
      return 'محدودیت تلاش رمز اصلی تمام شده است. لطفاً بعداً دوباره تلاش کنید.';
    case 'Vault data is invalid':
      return 'اطلاعات وارد شده معتبر نیست.';
    case 'Cryptographic operation failed':
      return 'عملیات امنیتی انجام نشد.';
    case 'Database operation failed':
      return 'ذخیره‌سازی انجام نشد.';
    case 'Unable to decrypt vault data':
      return 'خواندن اطلاعات گاوصندوق ممکن نشد.';
    case 'An unexpected error occurred':
      return 'خطای غیرمنتظره‌ای رخ داد.';
    case 'Backup password is incorrect':
      return 'رمز عبور فایل پشتیبان صحیح نیست.';
    case 'Backup file is invalid or corrupted':
      return 'فایل پشتیبان معتبر نیست یا آسیب دیده است.';
    case 'Backup version is not supported':
      return 'نسخه فایل پشتیبان پشتیبانی نمی‌شود.';
    case 'Backup file format is invalid':
      return 'ساختار فایل پشتیبان معتبر نیست.';
    case 'Unable to restore vault data':
      return 'بازیابی اطلاعات انجام نشد.';
    case 'Unable to save backup file':
      return 'ذخیره فایل پشتیبان انجام نشد.';
    case 'Unable to update screen capture protection':
      return 'به‌روزرسانی محافظت صفحه انجام نشد.';
    case 'A maximum of 5 items can be pinned.':
      return 'حداکثر ۵ مورد را می‌توانید سنجاق کنید.';
    case 'Gallery permission is required':
      return 'برای ذخیره تصویر در گالری، دسترسی لازم است.';
    case 'Unable to save image to gallery':
      return 'ذخیره تصویر در گالری انجام نشد.';
    case 'Gallery export is already in progress':
      return 'ذخیره تصاویر در گالری در حال انجام است.';
  }

  if (errorMessage.contains('Exception') ||
      errorMessage.contains('Hive') ||
      errorMessage.contains('Error:')) {
    return 'خطایی رخ داد. لطفاً دوباره تلاش کنید.';
  }

  return errorMessage;
}
