import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/category/util/category_name_validator.dart';

void main() {
  test('rejects empty and whitespace-only names', () {
    expect(
      CategoryNameValidator.validate(null, existingNames: const []),
      CategoryConstants.emptyNameMessage,
    );
    expect(
      CategoryNameValidator.validate('   ', existingNames: const []),
      CategoryConstants.emptyNameMessage,
    );
  });

  test('rejects names longer than the max length', () {
    expect(
      CategoryNameValidator.validate(
        'abcdefghijk',
        existingNames: const [],
      ),
      CategoryConstants.tooLongNameMessage,
    );
  });

  test('rejects duplicate names and allows the current name when editing', () {
    expect(
      CategoryNameValidator.validate('کاری', existingNames: const ['کاری']),
      CategoryConstants.duplicateNameMessage,
    );
    expect(
      CategoryNameValidator.validate(
        'کاری',
        existingNames: const ['کاری'],
        currentName: 'کاری',
      ),
      isNull,
    );
    expect(
      CategoryNameValidator.validate(
        'شخصی',
        existingNames: const ['کاری'],
        currentName: 'کاری',
      ),
      isNull,
    );
  });

  test('accepts a trimmed unique name', () {
    expect(
      CategoryNameValidator.validate('  پروژه  ', existingNames: const ['کاری']),
      isNull,
    );
  });
}
