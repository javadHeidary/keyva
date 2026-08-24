import 'package:keyva/feature/vault/model/category_item.dart';

class CategoryDefaults {
  CategoryDefaults._();

  static const personalId = 'cat_personal';
  static const workId = 'cat_work';
  static const financeId = 'cat_finance';

  static final createdAt = DateTime.utc(2026, 1, 1);

  static List<CategoryItem> get items => [
    CategoryItem(
      id: personalId,
      name: 'شخصی',
      icon: 'person',
      createdAt: createdAt,
    ),
    CategoryItem(
      id: financeId,
      name: 'مالی',
      icon: 'finance',
      createdAt: createdAt,
    ),
    CategoryItem(
      id: workId,
      name: 'کاری',
      icon: 'work',
      createdAt: createdAt,
    ),
  ];
}
