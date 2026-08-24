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
      'ورود با اثرانگشت روی این دستگاه در دسترس نیست.',
    );
  });

  test('maps biometric auth failed', () {
    expect(
      vaultUserMessage('Biometric authentication failed.'),
      'ورود با اثرانگشت ناموفق بود.',
    );
  });

  test('maps biometric not configured', () {
    expect(
      vaultUserMessage('Biometric unlock is not set up for this account.'),
      'ورود با اثرانگشت برای این حساب تنظیم نشده است.',
    );
  });

  test('maps biometric lockout', () {
    expect(
      vaultUserMessage('Biometric unlock is locked. Use your master password.'),
      'محدودیت تلاش ورود با اثرانگشت تمام شده است. اکنون فقط با رمز اصلی می‌توانید وارد شوید.',
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

  test('maps pin limit failure', () {
    expect(
      vaultUserMessage('A maximum of 5 items can be pinned.'),
      'حداکثر ۵ مورد را می‌توانید سنجاق کنید.',
    );
  });
}
