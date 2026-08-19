String vaultUserMessage(String? errorMessage) {
  if (errorMessage == null || errorMessage.trim().isEmpty) {
    return 'خطایی رخ داد. لطفاً دوباره تلاش کنید.';
  }

  switch (errorMessage) {
    case 'Unable to unlock your vault.':
      return 'باز کردن گاوصندوق ممکن نشد.';
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
  }

  if (errorMessage.contains('Exception') ||
      errorMessage.contains('Hive') ||
      errorMessage.contains('Error:')) {
    return 'خطایی رخ داد. لطفاً دوباره تلاش کنید.';
  }

  return errorMessage;
}
