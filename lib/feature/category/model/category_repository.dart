import 'package:keyva/feature/category/model/category_model.dart';

/// Phase 2: persistence and encryption-backed category storage.
abstract class CategoryRepository {
  Future<List<CategoryModel>> loadCategories();

  Future<void> saveCategories(List<CategoryModel> categories);
}
