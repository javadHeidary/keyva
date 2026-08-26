class AppInfo {
  const AppInfo._();

  static const version = '1.0.0';
  static const buildNumber = '1';
  static const displayVersion = '$version+$buildNumber';
  static const feedbackEmail = 'javadheidary.dev@gmail.com';
  static const supportEmailSubject = 'موضوع: ارتباط با پشتیبانی کیوا';
  static const feedbackEmailSubject = 'نقد و پیشنهاد برای کیوا';

  /// Official Telegram destination.
  static const telegramUrl = 'https://t.me/dEVHeidary';

  /// Official Bale destination (https opens in the Bale app or browser).
  static const baleUrl = 'https://ble.ir/devheidary';

  /// Optional extra Bale destination when [baleUrl] cannot be opened.
  static const baleFallbackUrl = '';
}
