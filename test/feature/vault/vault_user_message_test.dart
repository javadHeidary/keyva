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

  test('maps master password lockout', () {
    expect(
      vaultUserMessage(
        'Master password unlock is locked. Try again after the lockout ends.',
      ),
      'محدودیت تلاش رمز اصلی تمام شده است. لطفاً بعداً دوباره تلاش کنید.',
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

  test('maps gallery permission denied', () {
    expect(
      vaultUserMessage('Gallery permission is required'),
      'برای ذخیره تصویر در گالری، دسترسی لازم است.',
    );
  });

  test('maps gallery save failure', () {
    expect(
      vaultUserMessage('Unable to save image to gallery'),
      'ذخیره تصویر در گالری انجام نشد.',
    );
  });
}
