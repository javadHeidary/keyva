import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/shell/util/main_shell_navigation.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';

class HomeController extends GetxController {
  HomeController({
    VaultHomeViewModel? vault,
    VaultUnlockService? unlock,
  }) : _vaultOverride = vault,
       _unlockOverride = unlock;

  final VaultHomeViewModel? _vaultOverride;
  final VaultUnlockService? _unlockOverride;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final selectedType = Rxn<VaultItemType>();
  final selectedCategoryId = Rxn<String>();
  final trashItemCount = 0.obs;

  final accountOwnerName = UserProfile.defaultName.obs;
  final accountAvatarId = UserProfileAvatars.defaultId.obs;
  final accountGreeting = 'گاوصندوق شخصی شما';

  VaultHomeViewModel get vault =>
      _vaultOverride ?? Get.find<VaultHomeViewModel>();

  VaultUnlockService get _unlock =>
      _unlockOverride ?? getIt<VaultUnlockService>();

  VaultUiStatus get vaultStatus => vault.status.value;

  String get vaultErrorMessage => vaultUserMessage(vault.errorMessage.value);

  bool get isVaultSubmitting => vaultStatus == VaultUiStatus.submitting;

  bool get hasLoadedVault => vault.vault.value != null;

  void updateAccountProfile({required String name, required String avatarId}) {
    accountOwnerName.value = name;
    accountAvatarId.value = avatarId;
  }

  void openSettings() {
    switchMainShellTab(MainShellTab.settings);
  }

  Future<void> lock() async {
    await _unlock.lock();
    Get.offAllNamed(AppRoutes.authAccounts);
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

  List<VaultListItem> get vaultItems {
    vault.status.value;
    vault.searchQuery.value;
    return mapVaultVisibleItems(vault.visibleItems);
  }

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

  bool get isVaultEmpty => vaultStatus == VaultUiStatus.empty;

  List<VaultListItem> get visibleItems {
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
      return true;
    }).toList();
  }

  void syncLoginItems(List<VaultListItem> loginItems) {}

  void syncBankCardItems(List<VaultListItem> bankCardItems) {}

  void syncNoteItems(List<VaultListItem> noteItems) {}

  void incrementTrashCount() {}

  List<VaultListItem> itemsForType(VaultItemType type) {
    return vaultItems.where((item) => item.type == type).toList();
  }

  Object? sourceFor(String id) {
    for (final item in vault.visibleItems) {
      if (vaultItemId(item) == id) {
        return item;
      }
    }
    return findVaultItemById(vault.vault.value, id);
  }

  Future<void> loadVault() => vault.loadVault();

  Future<void> refreshVault() {
    if (vaultStatus == VaultUiStatus.loading) {
      return Future.value();
    }
    return vault.refreshVault();
  }

  void searchItems(String query) => vault.searchItems(query);

  void onHomeSearchTap() {
    Get.toNamed(AppRoutes.search);
  }

  void onTypeListSearchTap() {
    Get.toNamed(AppRoutes.search, arguments: Get.arguments);
  }

  void onTypeListMenuTap() {}

  @override
  void onInit() {
    super.onInit();
    selectedCategoryId.value = CategoryConstants.filterAllId;
  }

  @override
  void onReady() {
    super.onReady();
    if (vaultStatus == VaultUiStatus.initial) {
      loadVault();
    }
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
    switch (item.type) {
      case VaultItemType.login:
        Get.toNamed(AppRoutes.loginEdit, arguments: item.id);
        break;
      case VaultItemType.bankCard:
        Get.toNamed(AppRoutes.bankCardEdit, arguments: item.id);
        break;
      case VaultItemType.secureNote:
        Get.toNamed(AppRoutes.noteEdit, arguments: item.id);
        break;
    }
  }

  void onItemMoreAction(VaultListItem item, String action) {}

  void onTrashTap() {}

  void confirmDelete(BuildContext context, VaultListItem item) {
    if (isVaultSubmitting) {
      return;
    }

    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'حذف آیتم',
      description: '«${item.title}» برای همیشه حذف می‌شود. این کار قابل بازگشت نیست.',
      buttonText: 'حذف',
      onConfirm: () {
        if (isVaultSubmitting) {
          return;
        }
        vault.deleteItem(item.id);
      },
    );
  }

  void onCreateFirstItem() => onAddItemForType(VaultItemType.login);

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
}
