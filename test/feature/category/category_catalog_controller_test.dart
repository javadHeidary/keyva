import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/vault/model/category_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryCatalogController catalog;

  setUp(() {
    Get.testMode = true;
    catalog = CategoryCatalogController();
  });

  tearDown(Get.reset);

  test('starts empty without prototype seed categories', () {
    expect(catalog.categories, isEmpty);
    expect(catalog.vaultCategories, isEmpty);
    expect(catalog.userCategories, isEmpty);
  });

  test('replaceFromVault maps vault items into the UI catalog', () {
    catalog.replaceFromVault([
      CategoryItem(
        id: 'cat-1',
        name: 'Work',
        icon: 'work',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      CategoryItem(
        id: 'cat-2',
        name: 'Personal',
        icon: null,
        createdAt: DateTime.utc(2026, 8, 2),
      ),
    ]);

    expect(catalog.categories, hasLength(2));
    expect(catalog.categories[0].id, 'cat-1');
    expect(catalog.categories[0].name, 'Work');
    expect(catalog.categories[0].iconId, 'work');
    expect(catalog.categories[1].id, 'cat-2');
    expect(catalog.categories[1].name, 'Personal');
    expect(catalog.categories[1].iconId, 'folder');
    expect(catalog.vaultCategories.map((c) => c.id), ['cat-1', 'cat-2']);
    expect(catalog.findById('cat-1')?.name, 'Work');
    expect(catalog.labelForCategoryId('cat-1'), 'Work');
    expect(
      catalog.labelForCategoryId('missing'),
      CategoryConstants.withoutCategoryLabel,
    );
  });

  test('replaceFromVault clears previous catalog entries', () {
    catalog.replaceFromVault([
      CategoryItem(
        id: 'old',
        name: 'Old',
        icon: 'folder',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
    ]);
    catalog.replaceFromVault(const []);

    expect(catalog.categories, isEmpty);
  });
}
