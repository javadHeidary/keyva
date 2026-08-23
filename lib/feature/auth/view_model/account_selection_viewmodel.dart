import 'package:get/get.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/view/vault_user_message.dart';

enum AccountSelectionStatus { initial, loading, loaded, empty, error }

class AccountSelectionViewModel extends GetxController {
  AccountSelectionViewModel({required AuthRepository auth}) : _auth = auth;

  final AuthRepository _auth;

  final status = AccountSelectionStatus.initial.obs;
  final accounts = <AccountSummary>[].obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    status.value = AccountSelectionStatus.loading;
    errorMessage.value = '';
    final result = await _auth.getAccounts();
    if (result is FailureResult<List<AccountSummary>>) {
      accounts.clear();
      status.value = AccountSelectionStatus.error;
      errorMessage.value = vaultUserMessage(result.failure.message);
      return;
    }
    final list = (result as Success<List<AccountSummary>>).data;
    accounts.assignAll(list);
    if (list.isEmpty) {
      status.value = AccountSelectionStatus.empty;
      return;
    }
    if (list.length == 1) {
      final userId = list.first.id;
      await Future<void>.delayed(Duration.zero);
      if (isClosed) {
        return;
      }
      selectAccount(userId);
      return;
    }
    status.value = AccountSelectionStatus.loaded;
  }

  void selectAccount(String userId) {
    Get.offAllNamed(AppRoutes.authUnlock, arguments: userId);
  }

  void openRegister() {
    Get.toNamed(AppRoutes.authRegister);
  }

  void openRestore() {
    Get.toNamed(AppRoutes.authRestore);
  }
}
