import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

List<VaultListItem> mapVaultVisibleItems(
  Iterable<Object> items, {
  VaultData? vault,
}) {
  final result = <VaultListItem>[];
  for (final item in items) {
    final mapped = mapVaultListItem(item, vault: vault);
    if (mapped != null) {
      result.add(mapped);
    }
  }
  return result;
}

VaultListItem? mapVaultListItem(Object item, {VaultData? vault}) {
  return switch (item) {
    LoginItem login => VaultListItem(
      id: login.id,
      type: VaultItemType.login,
      title: login.title,
      subtitle: login.username,
      categoryId: login.categoryId ?? '',
      isPinned: login.isPinned,
    ),
    BankCardItem card => VaultListItem(
      id: card.id,
      type: VaultItemType.bankCard,
      title: card.title,
      subtitle: card.bankName,
      categoryId: card.categoryId ?? '',
      isPinned: card.isPinned,
    ),
    SecureNoteItem note => VaultListItem(
      id: note.id,
      type: VaultItemType.secureNote,
      title: note.title,
      subtitle: 'یادداشت امن',
      categoryId: note.categoryId ?? '',
      isPinned: note.isPinned,
    ),
    ImageFolder folder => VaultListItem(
      id: folder.id,
      type: VaultItemType.image,
      title: folder.title,
      subtitle: _photoCountLabel(vault?.photoCountForFolder(folder.id) ?? 0),
      categoryId: folder.categoryId ?? '',
      isPinned: folder.isPinned,
    ),
    _ => null,
  };
}

String _photoCountLabel(int count) => '$count عکس';

String? vaultItemId(Object item) {
  return switch (item) {
    LoginItem login => login.id,
    BankCardItem card => card.id,
    SecureNoteItem note => note.id,
    ImageFolder folder => folder.id,
    ImageItem image => image.id,
    CategoryItem category => category.id,
    _ => null,
  };
}

bool vaultItemIsPinned(Object item) {
  return switch (item) {
    LoginItem login => login.isPinned,
    BankCardItem card => card.isPinned,
    SecureNoteItem note => note.isPinned,
    ImageFolder folder => folder.isPinned,
    _ => false,
  };
}

Object? findVaultItemById(VaultData? data, String id) {
  if (data == null || id.isEmpty) {
    return null;
  }
  for (final item in data.logins) {
    if (item.id == id) {
      return item;
    }
  }
  for (final item in data.bankCards) {
    if (item.id == id) {
      return item;
    }
  }
  for (final item in data.secureNotes) {
    if (item.id == id) {
      return item;
    }
  }
  for (final item in data.imageFolders) {
    if (item.id == id) {
      return item;
    }
  }
  for (final item in data.images) {
    if (item.id == id) {
      return item;
    }
  }
  for (final item in data.categories) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

String vaultCategoryLabel(VaultData? data, String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) {
    return CategoryConstants.withoutCategoryLabel;
  }
  if (data == null) {
    return CategoryConstants.withoutCategoryLabel;
  }
  for (final category in data.categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }
  return CategoryConstants.withoutCategoryLabel;
}
