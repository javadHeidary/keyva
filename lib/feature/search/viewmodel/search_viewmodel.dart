import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/vault/view/vault_list_item_mapper.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';

class SearchViewModel extends GetxController {
  static const _searchDebounceMs = 300;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final results = <VaultListItem>[].obs;

  Timer? _debounceTimer;

  HomeController get _homeController => Get.find<HomeController>();

  VaultHomeViewModel get _vault => Get.find<VaultHomeViewModel>();

  VaultItemType? get filterType {
    final args = Get.arguments;
    if (args is VaultItemType) return args;
    return null;
  }

  String get hintText {
    final type = filterType;
    if (type == null) return 'جستجو...';
    return 'جستجو در ${type.label}...';
  }

  String? get typeLabel => filterType?.label;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchTextChanged);
    _applyResults();
  }

  @override
  void onReady() {
    super.onReady();
    searchFocusNode.requestFocus();
  }

  void _onSearchTextChanged() {
    final query = searchController.text;
    searchQuery.value = query;

    _debounceTimer?.cancel();
    isSearching.value = true;
    _debounceTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      _performSearch,
    );
  }

  void _performSearch() {
    if (Get.isRegistered<VaultHomeViewModel>()) {
      _vault.searchItems(searchQuery.value);
    }
    _applyResults();
    isSearching.value = false;
  }

  void _applyResults() {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      results.clear();
      return;
    }

    final mapped = mapVaultVisibleItems(_vault.visibleItems);
    final type = filterType;
    if (type == null) {
      results.assignAll(mapped);
      return;
    }
    results.assignAll(mapped.where((item) => item.type == type));
  }

  bool get isVaultContentEmpty {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      return true;
    }
    final data = _vault.vault.value;
    if (data == null) {
      return true;
    }
    return data.logins.isEmpty &&
        data.bankCards.isEmpty &&
        data.secureNotes.isEmpty;
  }

  void reloadFromVault() {
    searchController.clear();
    searchQuery.value = '';
    if (Get.isRegistered<VaultHomeViewModel>()) {
      _vault.searchItems('');
    }
    _applyResults();
    isSearching.value = false;
  }

  void onItemTap(VaultListItem item) => _homeController.onItemTap(item);

  void confirmDelete(BuildContext context, VaultListItem item) {
    _homeController.confirmDelete(context, item);
  }

  Object? sourceFor(String id) => _homeController.sourceFor(id);

  @override
  void onClose() {
    _debounceTimer?.cancel();
    if (Get.isRegistered<VaultHomeViewModel>()) {
      _vault.searchItems('');
    }
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
