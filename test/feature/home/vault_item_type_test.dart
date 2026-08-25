import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/vault_models.dart';

void main() {
  test('image type uses folder-first labels', () {
    expect(VaultItemType.image.label, 'تصاویر');
    expect(VaultItemType.image.listTitle, 'تصاویر');
    expect(VaultItemType.values, contains(VaultItemType.image));
  });
}
