class SupportUsContent {
  const SupportUsContent._();

  static const rateTitle = 'امتیاز به Keyva';
  static const otherAppsTitle = 'اپلیکیشن‌های دیگر ما';
  static const shareTitle = 'اشتراک‌گذاری Keyva';
  static const shareSubject = 'Keyva';

  static const rateUnavailable = 'امکان باز کردن صفحه امتیازدهی وجود ندارد.';
  static const otherAppsUnconfigured =
      'لیست اپلیکیشن‌ها در حال حاضر در دسترس نیست.';
  static const otherAppsUnavailable =
      'امکان باز کردن لیست اپلیکیشن‌ها وجود ندارد.';
  static const shareUnavailableTitle = 'اشتراک‌گذاری';
  static const shareUnavailableMessage = 'اشتراک‌گذاری انجام نشد';

  static String shareText(String storeUrl) {
    return 'من از Keyva برای مدیریت امن اطلاعاتم استفاده می‌کنم 🔐\n'
        '\n'
        'اگر به یک Password Manager ساده و امن نیاز داری،\n'
        'Keyva رو امتحان کن.\n'
        '\n'
        'دانلود Keyva:\n'
        '$storeUrl';
  }
}
