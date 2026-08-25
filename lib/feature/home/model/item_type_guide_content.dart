import 'package:keyva/feature/home/model/vault_models.dart';

class ItemTypeGuideContent {
  const ItemTypeGuideContent({
    required this.title,
    required this.description,
    required this.examples,
  });

  final String title;
  final String description;
  final List<String> examples;

  static ItemTypeGuideContent forType(VaultItemType type) {
    switch (type) {
      case VaultItemType.login:
        return login;
      case VaultItemType.bankCard:
        return bankCard;
      case VaultItemType.secureNote:
        return secureNote;
    }
  }

  static const login = ItemTypeGuideContent(
    title: 'اکانت چیست؟',
    description:
        'اکانت برای ذخیره ورود به سایت‌ها و اپلیکیشن‌هاست. '
        'می‌توانید نام کاربری، رمز عبور و آدرس وب را در آن نگه دارید.',
    examples: [
      'حساب جیمیل',
      'حساب اینستاگرام',
      'حساب تلگرام',
      'حساب یک وب‌سایت',
    ],
  );

  static const bankCard = ItemTypeGuideContent(
    title: 'کارت بانکی چیست؟',
    description:
        'کارت بانکی برای نگهداری اطلاعات کارت‌های شماست. '
        'می‌توانید شماره کارت، نام بانک و تاریخ انقضا را در آن ذخیره کنید.',
    examples: ['کارت بانکی شخصی', 'کارت بانکی شغلی', 'کارت بانکی دوم'],
  );

  static const secureNote = ItemTypeGuideContent(
    title: 'یادداشت چیست؟',
    description:
        'یادداشت برای نگهداری اطلاعات مهم و خصوصی است که در قالب '
        'اکانت یا کارت بانکی جا نمی‌گیرند.',
    examples: [
      'اطلاعات شخصی مهم',
      'اطلاعات مربوط به مدارک',
      'یادداشت‌های خصوصی',
    ],
  );
}
