import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/category/controller/category_catalog_controller.dart';
import 'package:keyva/feature/category/model/category_constants.dart';
import 'package:keyva/feature/home/model/item_type_guide_content.dart';
import 'package:keyva/feature/home/model/item_type_guide_status.dart';
import 'package:keyva/feature/home/model/item_type_sample_factory.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/widget/item_type_guide_dialog.dart';
import 'package:keyva/feature/settings/model/settings_repository.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/shell/util/main_shell_navigation.dart';
import 'package:keyva/feature/shell/viewmodel/main_shell_viewmodel.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';
import 'package:keyva/shared/widget/app_dialog_widget.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class HomeController extends GetxController {
  HomeController({
    VaultHomeViewModel? vault,
    VaultUnlockService? unlock,
    AuthRepository? auth,
    VaultSession? session,
    SettingsRepository? settings,
    ItemTypeSampleFactory sampleFactory = const ItemTypeSampleFactory(),
  }) : _vaultOverride = vault,
       _unlockOverride = unlock,
       _authOverride = auth,
       _sessionOverride = session,
       _settingsOverride = settings,
       _sampleFactory = sampleFactory;

  final VaultHomeViewModel? _vaultOverride;
  final VaultUnlockService? _unlockOverride;
  final AuthRepository? _authOverride;
  final VaultSession? _sessionOverride;
  final SettingsRepository? _settingsOverride;
  final ItemTypeSampleFactory _sampleFactory;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final createFabKey = GlobalKey<ExpandableFabState>();
  final selectedType = Rxn<VaultItemType>();
  final selectedCategoryId = Rxn<String>();
  final trashItemCount = 0.obs;

  final accountOwnerName = UserProfile.defaultName.obs;
  final accountGreeting = 'گاوصندوق شخصی شما';
  final typeGuideStatuses = <VaultItemType, ItemTypeGuideStatus>{}.obs;
  final isCreatingTypeGuideSample = false.obs;

  VaultHomeViewModel get vault =>
      _vaultOverride ?? Get.find<VaultHomeViewModel>();

  VaultUnlockService get _unlock =>
      _unlockOverride ?? getIt<VaultUnlockService>();

  VaultSession? get _session {
    if (_sessionOverride != null) {
      return _sessionOverride;
    }
    if (getIt.isRegistered<VaultSession>()) {
      return getIt<VaultSession>();
    }
    return null;
  }

  bool get isVaultUnlocked => _session?.isUnlocked ?? false;

  AuthRepository? get _auth {
    if (_authOverride != null) {
      return _authOverride;
    }
    if (getIt.isRegistered<AuthRepository>()) {
      return getIt<AuthRepository>();
    }
    return null;
  }

  SettingsRepository? get _settings {
    if (_settingsOverride != null) {
      return _settingsOverride;
    }
    if (getIt.isRegistered<SettingsRepository>()) {
      return getIt<SettingsRepository>();
    }
    return null;
  }

  VaultUiStatus get vaultStatus => vault.status.value;

  String get vaultErrorMessage => vaultUserMessage(vault.errorMessage.value);

  bool get isVaultSubmitting => vaultStatus == VaultUiStatus.submitting;

  bool get hasLoadedVault => vault.vault.value != null;

  bool get isVaultLoadPending =>
      !hasLoadedVault &&
      (vaultStatus == VaultUiStatus.initial ||
          vaultStatus == VaultUiStatus.loading);

  void updateAccountProfile({required String name}) {
    accountOwnerName.value = name;
  }

  Future<void> loadAccountProfile() async {
    final auth = _auth;
    if (auth == null) {
      return;
    }
    final loaded = await auth.currentUser();
    if (loaded is Success<UserRecord>) {
      updateAccountProfile(name: loaded.data.username);
    }
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
    return mapVaultVisibleItems(
      vault.visibleItems,
      vault: vault.vault.value,
    );
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

  bool get hasNoVaultItems => vaultItems.isEmpty;

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

  List<VaultListItem> itemsForCategory(String categoryId) {
    return vaultItems.where((item) => item.categoryId == categoryId).toList();
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
    for (final type in VaultItemType.values) {
      typeGuideStatuses.putIfAbsent(type, () => ItemTypeGuideStatus.unseen);
    }
    loadAccountProfile();
    loadTypeGuideStatuses();
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

  ItemTypeGuideStatus typeGuideStatus(VaultItemType type) {
    typeGuideStatuses[type];
    return typeGuideStatuses[type] ?? ItemTypeGuideStatus.unseen;
  }

  bool isTypeGuideVisible(VaultItemType type) {
    return typeGuideStatus(type).isVisible;
  }

  Future<void> loadTypeGuideStatuses() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    for (final type in VaultItemType.values) {
      final stored = await settings.loadItemTypeGuideStatus(type.name);
      typeGuideStatuses[type] = ItemTypeGuideStatusX.fromStorage(stored);
    }
  }

  void onTypeGuideInfoTap(BuildContext context, VaultItemType type) {
    showItemTypeGuideDialog(
      context,
      content: ItemTypeGuideContent.forType(type),
      isSubmitting: isCreatingTypeGuideSample,
      onCreateSample: () => createTypeGuideSample(context, type),
      onDontShowAgain: () =>
          dismissTypeGuide(context, type, ItemTypeGuideStatus.dismissed),
      onGotIt: () =>
          dismissTypeGuide(context, type, ItemTypeGuideStatus.acknowledged),
    );
  }

  Future<void> dismissTypeGuide(
    BuildContext context,
    VaultItemType type,
    ItemTypeGuideStatus status,
  ) async {
    if (isCreatingTypeGuideSample.value) {
      return;
    }

    final persisted = await _persistGuideStatus(type, status);
    if (!persisted) {
      if (context.mounted) {
        _showGuidePersistError(context);
      }
      return;
    }

    if (context.mounted &&
        Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> createTypeGuideSample(
    BuildContext context,
    VaultItemType type,
  ) async {
    if (isCreatingTypeGuideSample.value) {
      return;
    }
    if (!ItemTypeSampleFactory.supports(type)) {
      return;
    }

    isCreatingTypeGuideSample.value = true;
    try {
      final item = _sampleFactory.create(type);
      final itemId = vaultItemId(item);
      if (itemId == null || itemId.isEmpty) {
        if (context.mounted) {
          _showGuideCreateError(context, null);
        }
        return;
      }

      final result = await vault.addItem(item);
      if (result is FailureResult<void>) {
        if (context.mounted) {
          _showGuideCreateError(context, result.failure.message);
        }
        return;
      }

      final persisted = await _persistGuideStatus(
        type,
        ItemTypeGuideStatus.sampleCreated,
      );
      if (!persisted) {
        if (context.mounted) {
          _showGuidePersistError(context);
        }
        return;
      }

      if (context.mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      openVaultTypeList(type);
    } finally {
      isCreatingTypeGuideSample.value = false;
    }
  }

  Future<bool> _persistGuideStatus(
    VaultItemType type,
    ItemTypeGuideStatus status,
  ) async {
    final settings = _settings;
    if (settings == null) {
      typeGuideStatuses[type] = status;
      return true;
    }

    try {
      await settings.saveItemTypeGuideStatus(type.name, status.name);
      typeGuideStatuses[type] = status;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showGuideCreateError(BuildContext context, String? message) {
    AppToast.error(
      context,
      title: 'ساخت نمونه ممکن نشد',
      message: vaultUserMessage(message),
    );
  }

  void _showGuidePersistError(BuildContext context) {
    AppToast.error(
      context,
      title: 'ذخیره انجام نشد',
      message: vaultUserMessage('Database operation failed'),
    );
  }

  void onItemTap(VaultListItem item) {
    openVaultItemDetails(item.type, item.id);
  }

  void onItemMoreAction(VaultListItem item, String action) {}

  void onTrashTap() {}

  Future<void> toggleItemPin(BuildContext context, VaultListItem item) async {
    if (isVaultSubmitting) {
      return;
    }
    final result = await vault.setItemPinned(
      id: item.id,
      isPinned: !item.isPinned,
    );
    if (!context.mounted) {
      return;
    }
    if (result is FailureResult<void>) {
      AppToast.warning(
        context,
        title: 'حداکثر سنجاق',
        message: vaultUserMessage(result.failure.message),
      );
    }
  }

  void confirmDelete(
    BuildContext context,
    VaultListItem item, {
    VoidCallback? onDeleted,
  }) {
    if (isVaultSubmitting) {
      return;
    }

    AppDialogWidget.show(
      context,
      type: AppDialogType.warning,
      title: 'حذف آیتم',
      description: item.type == VaultItemType.image
          ? '«${item.title}» و همه عکس‌های داخل آن برای همیشه حذف می‌شوند. این کار قابل بازگشت نیست.'
          : '«${item.title}» برای همیشه حذف می‌شود. این کار قابل بازگشت نیست.',
      buttonText: 'حذف',
      cancelText: 'انصراف',
      onConfirm: () {
        if (isVaultSubmitting) {
          return;
        }
        vault.deleteItem(item.id);
        onDeleted?.call();
      },
    );
  }

  void onAddItem() {}

  void onAddItemForType(VaultItemType type, {String? categoryId}) {
    final arguments = categoryId != null && categoryId.isNotEmpty
        ? categoryId
        : null;
    switch (type) {
      case VaultItemType.login:
        Get.toNamed(AppRoutes.loginCreate, arguments: arguments);
        break;
      case VaultItemType.bankCard:
        Get.toNamed(AppRoutes.bankCardCreate, arguments: arguments);
        break;
      case VaultItemType.secureNote:
        Get.toNamed(AppRoutes.noteCreate, arguments: arguments);
        break;
      case VaultItemType.image:
        Get.toNamed(AppRoutes.imageFolderCreate, arguments: arguments);
        break;
    }
  }
}
