import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';

class HomeController extends GetxController {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final selectedType = Rxn<VaultItemType>();
  final selectedCategoryId = Rxn<String>();
  final trashItemCount = 2.obs;

  final accountOwnerName = UserProfile.defaultName.obs;
  final accountAvatarId = UserProfileAvatars.defaultId.obs;
  final accountGreeting = 'گاوصندوق شخصی شما';

  void updateAccountProfile({required String name, required String avatarId}) {
    accountOwnerName.value = name;
    accountAvatarId.value = avatarId;
  }

  void openSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  CategoryCatalogController? get _catalog =>
      Get.isRegistered<CategoryCatalogController>()
      ? Get.find<CategoryCatalogController>()
      : null;

  List<VaultCategory> get filterCategories {
    final catalog = _catalog;
    final user = catalog?.vaultCategories ?? const <VaultCategory>[];
    return [
      const VaultCategory(
        id: CategoryConstants.filterAllId,
        name: CategoryConstants.filterAllName,
      ),
      ...user,
    ];
  }

  final vaultItems = <VaultListItem>[
    const VaultListItem(
      id: '1',
      type: VaultItemType.login,
      title: 'ایمیل سازمانی',
      subtitle: 'ali.rezaei@company.ir',
      categoryId: 'work',
    ),
    const VaultListItem(
      id: '2',
      type: VaultItemType.bankCard,
      title: 'کارت بانک ملت',
      subtitle: 'بانک ملت',
      categoryId: 'finance',
    ),
    const VaultListItem(
      id: '3',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '4',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '5',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '6',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '7',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '4',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '5',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '6',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '7',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '4',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '5',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '6',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
    const VaultListItem(
      id: '7',
      type: VaultItemType.secureNote,
      title: 'کدهای بازیابی',
      subtitle: 'یادداشت پشتیبان',
      categoryId: 'personal',
    ),
  ].obs;

  List<VaultTypeSummary> get typeSummaries {
    final items = vaultItems;
    return VaultItemType.values
        .map(
          (type) => VaultTypeSummary(
            type: type,
            itemCount: items.where((item) => item.type == type).length,
          ),
        )
        .toList();
  }

  bool get isVaultEmpty => vaultItems.isEmpty;

  List<VaultListItem> get visibleItems {
    final query = searchQuery.value.trim().toLowerCase();
    final categoryId = selectedCategoryId.value;
    final type = selectedType.value;
    final items = vaultItems;

    return items.where((item) {
      if (type != null && item.type != type) return false;
      if (categoryId != null &&
          categoryId != CategoryConstants.filterAllId &&
          item.categoryId != categoryId) {
        return false;
      }
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  void syncLoginItems(List<VaultListItem> loginItems) {
    vaultItems.removeWhere((item) => item.type == VaultItemType.login);
    vaultItems.addAll(loginItems);
  }

  void syncBankCardItems(List<VaultListItem> bankCardItems) {
    vaultItems.removeWhere((item) => item.type == VaultItemType.bankCard);
    vaultItems.addAll(bankCardItems);
  }

  void syncNoteItems(List<VaultListItem> noteItems) {
    vaultItems.removeWhere((item) => item.type == VaultItemType.secureNote);
    vaultItems.addAll(noteItems);
  }

  void incrementTrashCount() {
    trashItemCount.value++;
  }

  List<VaultListItem> itemsForType(VaultItemType type) {
    return vaultItems.where((item) => item.type == type).toList();
  }

  void onTypeListSearchTap() {}

  void onTypeListMenuTap() {}

  @override
  void onInit() {
    super.onInit();
    selectedCategoryId.value = CategoryConstants.filterAllId;
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void selectType(VaultItemType type) {
    if (selectedType.value == type) {
      selectedType.value = null;
      return;
    }
    selectedType.value = type;
  }

  void selectCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
  }

  bool isTypeSelected(VaultItemType type) => selectedType.value == type;

  bool isCategorySelected(String categoryId) =>
      selectedCategoryId.value == categoryId;

  void onOpenDrawer() {}

  void onTypeMoreActions(VaultItemType type) {}

  void onItemTap(VaultListItem item) {
    if (item.type == VaultItemType.login) {
      Get.toNamed(AppRoutes.loginDetails, arguments: item.id);
      return;
    }
    if (item.type == VaultItemType.bankCard) {
      Get.toNamed(AppRoutes.bankCardDetails, arguments: item.id);
      return;
    }
    if (item.type == VaultItemType.secureNote) {
      Get.toNamed(AppRoutes.noteDetails, arguments: item.id);
    }
  }

  void onItemMoreAction(VaultListItem item, String action) {}

  void onTrashTap() {}

  void onCreateFirstItem() {}

  void onAddItem() {}

  void onAddItemForType(VaultItemType type) {
    switch (type) {
      case VaultItemType.login:
        Get.toNamed(AppRoutes.loginCreate);
        break;
      case VaultItemType.bankCard:
        Get.toNamed(AppRoutes.bankCardCreate);
        break;
      case VaultItemType.secureNote:
        Get.toNamed(AppRoutes.noteCreate);
        break;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
