import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

class VaultItemViewModel extends GetxController {
  VaultItemViewModel({required VaultOperationService operations})
    : _operations = operations;

  final VaultOperationService _operations;

  final status = VaultUiStatus.initial.obs;
  final errorMessage = Rxn<String>();
  final currentItem = Rxn<Object>();

  Future<void> create(Object item) {
    return _submit(item, _operations.addItem);
  }

  Future<void> updateItem(Object item) {
    return _submit(item, _operations.updateItem);
  }

  Future<void> _submit(
    Object item,
    Future<Result<void>> Function(Object item) run,
  ) async {
    if (!_isValid(item)) {
      status.value = VaultUiStatus.error;
      errorMessage.value = const ValidationFailure().message;
      return;
    }

    currentItem.value = item;
    status.value = VaultUiStatus.submitting;
    errorMessage.value = null;

    final result = await run(item);
    if (result is FailureResult<void>) {
      status.value = VaultUiStatus.error;
      errorMessage.value = result.failure.message;
      return;
    }

    status.value = VaultUiStatus.success;
  }

  static bool _isValid(Object item) {
    return switch (item) {
      LoginItem login =>
        login.id.isNotEmpty &&
            login.title.isNotEmpty &&
            login.username.isNotEmpty &&
            login.password.isNotEmpty,
      BankCardItem card =>
        card.id.isNotEmpty &&
            card.title.isNotEmpty &&
            card.cardNumber.isNotEmpty &&
            card.cardHolder.isNotEmpty &&
            card.expiryDate.isNotEmpty &&
            card.cvv.isNotEmpty &&
            card.bankName.isNotEmpty,
      SecureNoteItem note =>
        note.id.isNotEmpty && note.title.isNotEmpty && note.content.isNotEmpty,
      ImageFolder folder => folder.id.isNotEmpty && folder.title.isNotEmpty,
      ImageItem image =>
        image.id.isNotEmpty &&
            image.folderId.isNotEmpty &&
            image.blobId.isNotEmpty &&
            image.thumbnailBlobId.isNotEmpty &&
            image.mimeType.isNotEmpty &&
            image.width > 0 &&
            image.height > 0,
      CategoryItem category =>
        category.id.isNotEmpty && category.name.isNotEmpty,
      _ => false,
    };
  }
}
