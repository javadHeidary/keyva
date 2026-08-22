import 'package:get/get.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

Future<void> submitVaultItem({
  required VaultItemViewModel items,
  required RxBool isSubmitting,
  required Rxn<String> submitError,
  required Future<void> Function() run,
  void Function()? onSuccess,
}) async {
  if (isSubmitting.value || items.status.value == VaultUiStatus.submitting) {
    return;
  }

  submitError.value = null;
  isSubmitting.value = true;
  try {
    await run();
  } finally {
    isSubmitting.value = false;
  }

  if (items.status.value == VaultUiStatus.success) {
    submitError.value = null;
    if (Get.isRegistered<VaultHomeViewModel>()) {
      await Get.find<VaultHomeViewModel>().refreshVault();
    }
    if (onSuccess != null) {
      onSuccess();
    } else {
      Get.back(result: true);
    }
    return;
  }

  submitError.value = vaultUserMessage(items.errorMessage.value);
}
