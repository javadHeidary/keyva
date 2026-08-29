import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/util/vault_more_actions.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/shared/icons/app_icons.dart';

void main() {
  final folder = ImageFolder(
    id: 'folder-1',
    title: 'ID',
    categoryId: null,
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  );

  const item = VaultListItem(
    id: 'folder-1',
    type: VaultItemType.image,
    title: 'ID',
    subtitle: '1 عکس',
    categoryId: '',
  );

  test('omits folder gallery export when the callback is missing', () {
    final actions = vaultMoreActionsForItem(item, source: folder);
    expect(
      actions.any((action) => action.label == 'ذخیره همه تصاویر در گالری'),
      isFalse,
    );
  });

  test('adds folder gallery export when a callback is provided', () {
    var tapped = false;
    final actions = vaultMoreActionsForItem(
      item,
      source: folder,
      onExportFolderImages: () => tapped = true,
    );
    final export = actions.singleWhere(
      (action) => action.label == 'ذخیره همه تصاویر در گالری',
    );
    expect(export.icon, AppIcon.download);
    export.onPressed!();
    expect(tapped, isTrue);
  });
}
