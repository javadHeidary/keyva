import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';

class SearchViewModel extends GetxController {
  static const _searchDebounceMs = 300;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final results = <VaultListItem>[].obs;

  Timer? _debounceTimer;

  HomeController get _homeController => Get.find<HomeController>();

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

    if (query.trim().isEmpty) {
      isSearching.value = false;
      results.clear();
      return;
    }

    isSearching.value = true;
    _debounceTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      _performSearch,
    );
  }

  void _performSearch() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      isSearching.value = false;
      results.clear();
      return;
    }

    final type = filterType;
    final items = _homeController.vaultItems;

    results.assignAll(
      items.where((item) {
        if (type != null && item.type != type) return false;
        return item.title.toLowerCase().contains(query) ||
            item.subtitle.toLowerCase().contains(query);
      }),
    );

    isSearching.value = false;
  }

  void onItemTap(VaultListItem item) => _homeController.onItemTap(item);

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
