import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/vault_models.dart';

void main() {
  test('login user-facing label changes without renaming the type', () {
    expect(VaultItemType.login.name, 'login');
    expect(VaultItemType.login.label, 'اکانت‌ها');
    expect(VaultItemType.login.listTitle, 'لیست اکانت‌ها');
    expect(VaultItemType.values, contains(VaultItemType.login));
  });
}
