import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

class VaultHomeViewModel extends GetxController {
  VaultHomeViewModel({required VaultOperationService operations})
    : _operations = operations;

  final VaultOperationService _operations;

  final status = VaultUiStatus.initial.obs;
  final vault = Rxn<VaultData>();
  final visibleItems = <Object>[].obs;
  final searchQuery = ''.obs;
  final errorMessage = Rxn<String>();

  Future<void> loadVault() async {
    status.value = VaultUiStatus.loading;
    errorMessage.value = null;

    final result = await _operations.getVault();
    if (result is FailureResult<VaultData>) {
      _setError(result.failure);
      return;
    }

    final data = (result as Success<VaultData>).data;
    vault.value = data;
    _applyVisibleItems(data);
  }

  Future<void> refreshVault() => loadVault();

  void searchItems(String query) {
    searchQuery.value = query;
    final current = vault.value;
    if (current == null) {
      return;
    }
    _applyVisibleItems(current);
  }

  Future<void> deleteItem(String id) async {
    status.value = VaultUiStatus.submitting;
    errorMessage.value = null;

    final result = await _operations.deleteItem(id);
    if (result is FailureResult<void>) {
      _setError(result.failure);
      return;
    }

    await loadVault();
  }

  void _applyVisibleItems(VaultData data) {
    if (_isEmpty(data)) {
      visibleItems.clear();
      status.value = VaultUiStatus.empty;
      return;
    }

    final needle = searchQuery.value.trim();
    visibleItems.assignAll([
      for (final item in _flatten(data))
        if (_matches(item, needle)) item,
    ]);
    status.value = VaultUiStatus.loaded;
  }

  void _setError(AppFailure failure) {
    status.value = VaultUiStatus.error;
    errorMessage.value = failure.message;
  }

  static bool _isEmpty(VaultData data) {
    return data.logins.isEmpty &&
        data.bankCards.isEmpty &&
        data.secureNotes.isEmpty &&
        data.categories.isEmpty;
  }

  static List<Object> _flatten(VaultData data) {
    return <Object>[
      ...data.logins,
      ...data.bankCards,
      ...data.secureNotes,
      ...data.categories,
    ];
  }

  static bool _matches(Object item, String query) {
    if (query.isEmpty) {
      return true;
    }
    final needle = query.toLowerCase();
    return switch (item) {
      LoginItem login => _contains(needle, [
        login.title,
        login.username,
        login.website,
        login.notes,
      ]),
      BankCardItem card => _contains(needle, [
        card.title,
        card.cardHolder,
        card.bankName,
        card.notes,
      ]),
      SecureNoteItem note => _contains(needle, [note.title, note.content]),
      CategoryItem category => _contains(needle, [category.name]),
      _ => false,
    };
  }

  static bool _contains(String needle, List<String?> fields) {
    for (final field in fields) {
      if (field != null && field.toLowerCase().contains(needle)) {
        return true;
      }
    }
    return false;
  }
}
