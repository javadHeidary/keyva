import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';

void main() {
  test('websiteHostForFavicon returns a host for a valid URL', () {
    expect(websiteHostForFavicon('https://mail.test/path'), 'mail.test');
    expect(websiteHostForFavicon('mail.test'), 'mail.test');
  });

  test('websiteHostForFavicon returns null for missing or invalid values', () {
    expect(websiteHostForFavicon(null), isNull);
    expect(websiteHostForFavicon(''), isNull);
    expect(websiteHostForFavicon('   '), isNull);
  });

  test('favicon cache key is host-scoped', () {
    expect(faviconCacheKeyForHost('mail.test'), 'favicon:mail.test');
    expect(
      faviconUrlForHost('mail.test'),
      'https://www.google.com/s2/favicons?domain=mail.test&sz=128',
    );
  });
}
