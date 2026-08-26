import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/item_type_guide_content.dart';
import 'package:keyva/feature/home/model/vault_models.dart';

void main() {
  test('login content explains accounts with practical examples', () {
    final content = ItemTypeGuideContent.forType(VaultItemType.login);

    expect(content.title, 'اکانت چیست؟');
    expect(content.description, contains('نام کاربری'));
    expect(content.examples, containsAll(['حساب جیمیل', 'حساب اینستاگرام']));
  });

  test('bank card content explains cards independently from login', () {
    final content = ItemTypeGuideContent.forType(VaultItemType.bankCard);

    expect(content.title, 'کارت بانکی چیست؟');
    expect(content.description, contains('شماره کارت'));
    expect(content.examples, contains('کارت بانکی شخصی'));
    expect(
      content.title,
      isNot(ItemTypeGuideContent.forType(VaultItemType.login).title),
    );
  });

  test('secure note content explains notes independently', () {
    final content = ItemTypeGuideContent.forType(VaultItemType.secureNote);

    expect(content.title, 'یادداشت چیست؟');
    expect(content.examples, contains('یادداشت‌های خصوصی'));
  });

  test('image content explains folders first', () {
    final content = ItemTypeGuideContent.forType(VaultItemType.image);

    expect(content.title, 'پوشه تصاویر چیست؟');
    expect(content.description, contains('پوشه'));
    expect(content.examples, contains('عکس‌های شناسنامه'));
  });

  test('only login, bank card, and note offer a sample item', () {
    expect(ItemTypeGuideContent.login.canCreateSample, isTrue);
    expect(ItemTypeGuideContent.bankCard.canCreateSample, isTrue);
    expect(ItemTypeGuideContent.secureNote.canCreateSample, isTrue);
    expect(ItemTypeGuideContent.image.canCreateSample, isFalse);
  });
}
