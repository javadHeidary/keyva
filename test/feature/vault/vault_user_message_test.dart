import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';

void main() {
  test('maps generic unlock failure', () {
    expect(
      vaultUserMessage('Unable to unlock your vault.'),
      'باز کردن گاوصندوق ممکن نشد.',
    );
  });

  test('maps biometric unavailable', () {
    expect(
      vaultUserMessage('Biometric authentication is unavailable.'),
      'احراز هویت بیومتریک روی این دستگاه در دسترس نیست.',
    );
  });

  test('maps biometric auth failed', () {
    expect(
      vaultUserMessage('Biometric authentication failed.'),
      'احراز هویت بیومتریک ناموفق بود.',
    );
  });

  test('maps biometric not configured', () {
    expect(
      vaultUserMessage('Biometric unlock is not set up for this account.'),
      'باز کردن با اثر انگشت یا چهره برای این حساب تنظیم نشده است.',
    );
  });

  test('does not show raw platform exceptions', () {
    expect(
      vaultUserMessage('PlatformException(no_fragment_activity, ...)'),
      'خطایی رخ داد. لطفاً دوباره تلاش کنید.',
    );
  });

  test('maps screen protection failure', () {
    expect(
      vaultUserMessage('Unable to update screen capture protection'),
      'به‌روزرسانی محافظت صفحه انجام نشد.',
    );
  });
}
