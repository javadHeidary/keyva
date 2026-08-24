class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class FaqContent {
  FaqContent._();

  static const items = <FaqItem>[
    FaqItem(
      question: 'کیوا داده‌های من را کجا نگه می‌دارد؟',
      answer:
          'همه اطلاعات روی دستگاه شما و به‌صورت رمزنگاری‌شده ذخیره می‌شوند. '
          'سرور ابری برای گاوصندوق شخصی استفاده نمی‌شود.',
    ),
    FaqItem(
      question: 'اگر Master Password را فراموش کنم چه می‌شود؟',
      answer:
          'به‌دلیل امنیت، بازیابی Master Password از طریق سرور ممکن نیست. '
          'پشتیبان محلی را فقط در صورت داشتن رمز صحیح می‌توان بازیابی کرد.',
    ),
    FaqItem(
      question: 'تفاوت PIN و ورود با اثرانگشت با Master Password چیست؟',
      answer:
          'Master Password مبنای رمزنگاری داده‌هاست. PIN و ورود با اثرانگشت '
          'فقط برای باز کردن سریع‌تر برنامه پس از قفل شدن استفاده می‌شوند.',
    ),
    FaqItem(
      question: 'چگونه از گاوصندوق پشتیبان بگیرم؟',
      answer:
          'از تنظیمات → پشتیبان‌گیری و بازیابی می‌توانید فایل پشتیبان محلی '
          'ایجاد یا بازیابی کنید (پس از فعال‌سازی کامل این قابلیت).',
    ),
  ];
}
