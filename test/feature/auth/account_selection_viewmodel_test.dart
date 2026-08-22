import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/auth/model/account_summary.dart';
import 'package:keyva/feature/auth/view_model/account_selection_viewmodel.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late AccountSelectionViewModel viewModel;

  setUp(() {
    Get.testMode = true;
    auth = FakeAuthRepository();
    viewModel = AccountSelectionViewModel(auth: auth);
  });

  tearDown(Get.reset);

  test('empty accounts expose the empty state', () async {
    auth.accounts = const [];
    await viewModel.loadAccounts();
    expect(viewModel.status.value, AccountSelectionStatus.empty);
    expect(viewModel.accounts, isEmpty);
  });

  test('multiple accounts are loaded for selection', () async {
    auth.accounts = const [
      AccountSummary(id: 'user-a', username: 'علی'),
      AccountSummary(id: 'user-b', username: 'رضا'),
    ];
    await viewModel.loadAccounts();
    expect(viewModel.status.value, AccountSelectionStatus.loaded);
    expect(viewModel.accounts, hasLength(2));
    expect(viewModel.accounts.map((account) => account.username), ['علی', 'رضا']);
  });

  test('account lookup failure exposes the error state', () async {
    auth = FakeGetAccountsFailure();
    viewModel = AccountSelectionViewModel(auth: auth);
    await viewModel.loadAccounts();
    expect(viewModel.status.value, AccountSelectionStatus.error);
    expect(viewModel.errorMessage.value, isNotEmpty);
  });
}

class FakeGetAccountsFailure extends FakeAuthRepository {
  @override
  Future<Result<List<AccountSummary>>> getAccounts() async {
    return const FailureResult(DatabaseFailure());
  }
}
