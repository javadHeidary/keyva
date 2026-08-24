class AppInfo {
  const AppInfo._();

  static const version = '1.0.0';
  static const buildNumber = '1';
  static const displayVersion = '$version+$buildNumber';
  static const feedbackEmail = 'support@keyva.app';
  static const supportEmailSubject = 'موضوع: ارتباط با پشتیبانی Keyva';

  /// Official Telegram destination. Empty until a real URL is configured.
  static const telegramUrl = '';

  /// Preferred Bale app destination (custom scheme or https). Empty if unset.
  static const baleUrl = '';

  /// https fallback when the Bale app cannot be opened. Empty if unset.
  static const baleFallbackUrl = '';
}
