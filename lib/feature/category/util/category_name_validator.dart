import 'package:keyva/feature/category/model/category_constants.dart';

class CategoryNameValidator {
  CategoryNameValidator._();

  static String? validate(
    String? value, {
    required Iterable<String> existingNames,
    String? currentName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return CategoryConstants.emptyNameMessage;
    }
    final name = value.trim();
    if (name.length > CategoryConstants.maxNameLength) {
      return CategoryConstants.tooLongNameMessage;
    }
    for (final existing in existingNames) {
      if (currentName != null && existing == currentName) {
        continue;
      }
      if (existing == name) {
        return CategoryConstants.duplicateNameMessage;
      }
    }
    return null;
  }
}
