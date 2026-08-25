import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeVaultOperationService operations;
  late VaultItemViewModel viewModel;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
    String username = 'keep-this-user',
    String password = 'keep-this-password',
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: username,
      password: password,
      website: 'https://mail.test',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({
    String id = 'card-1',
    String title = 'Travel',
    String cardNumber = '6219861234567890',
  }) {
    return BankCardItem(
      id: id,
      title: title,
      cardNumber: cardNumber,
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Saman',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note({
    String id = 'note-1',
    String title = 'Gate',
    String content = 'building-code-42',
  }) {
    return SecureNoteItem(
      id: id,
      title: title,
      content: content,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category({String id = 'cat-1', String name = 'Work'}) {
    return CategoryItem(
      id: id,
      name: name,
      icon: 'inbox',
      createdAt: createdAt,
    );
  }

  setUp(() {
    operations = _FakeVaultOperationService();
    viewModel = VaultItemViewModel(operations: operations);
  });

  group('create', () {
    test('starts in the initial state', () {
      expect(viewModel.status.value, VaultUiStatus.initial);
      expect(viewModel.currentItem.value, isNull);
      expect(viewModel.errorMessage.value, isNull);
    });

    test('sets submitting then success and calls addItem', () async {
      final item = login();
      operations.addGate = Completer<void>();

      final future = viewModel.create(item);
      expect(viewModel.status.value, VaultUiStatus.submitting);
      expect(viewModel.currentItem.value, item);

      operations.addGate!.complete();
      await future;

      expect(viewModel.status.value, VaultUiStatus.success);
      expect(operations.lastAdded, same(item));
      expect(operations.addCount, 1);
      expect(operations.updateCount, 0);
      expect(viewModel.errorMessage.value, isNull);
    });

    test('maps ValidationFailure to a presentation error', () async {
      operations.addFailure = const ValidationFailure();

      await viewModel.create(login());

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Vault data is invalid');
      expect(operations.addCount, 1);
    });

    test('maps CryptoFailure to a presentation error', () async {
      operations.addFailure = const CryptoFailure();

      await viewModel.create(login());

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Cryptographic operation failed');
    });

    test('maps AuthenticationFailure to a presentation error', () async {
      operations.addFailure = const AuthenticationFailure();

      await viewModel.create(login());

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Unable to unlock your vault.');
    });

    test('does not call the operation when local validation fails', () async {
      await viewModel.create(login(title: ''));

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Vault data is invalid');
      expect(viewModel.currentItem.value, isNull);
      expect(operations.addCount, 0);
      expect(operations.lastAdded, isNull);
    });

    test(
      'rejects an unknown item type without calling the operation',
      () async {
        await viewModel.create('not-an-item');

        expect(viewModel.status.value, VaultUiStatus.error);
        expect(viewModel.errorMessage.value, 'Vault data is invalid');
        expect(operations.addCount, 0);
      },
    );

    test('rejects empty required fields on each item type', () async {
      await viewModel.create(login(id: ''));
      expect(operations.addCount, 0);

      await viewModel.create(card(cardNumber: ''));
      expect(operations.addCount, 0);

      await viewModel.create(note(content: ''));
      expect(operations.addCount, 0);

      await viewModel.create(category(name: ''));
      expect(operations.addCount, 0);

      await viewModel.create(
        ImageFolder(
          id: '',
          title: 'Photos',
          categoryId: null,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
      expect(operations.addCount, 0);
    });
  });

  group('update', () {
    test('sets submitting then success and calls updateItem', () async {
      final item = login(title: 'Updated mail');
      operations.updateGate = Completer<void>();

      final future = viewModel.updateItem(item);
      expect(viewModel.status.value, VaultUiStatus.submitting);
      expect(viewModel.currentItem.value, item);

      operations.updateGate!.complete();
      await future;

      expect(viewModel.status.value, VaultUiStatus.success);
      expect(operations.lastUpdated, same(item));
      expect(operations.updateCount, 1);
      expect(operations.addCount, 0);
    });

    test('maps DatabaseFailure to a presentation error', () async {
      operations.updateFailure = const DatabaseFailure();

      await viewModel.updateItem(login());

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Database operation failed');
      expect(operations.updateCount, 1);
    });

    test('does not call the operation when local validation fails', () async {
      await viewModel.updateItem(login(username: ''));

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Vault data is invalid');
      expect(operations.updateCount, 0);
      expect(operations.lastUpdated, isNull);
    });
  });
}

class _FakeVaultOperationService implements VaultOperationService {
  AppFailure? addFailure;
  AppFailure? updateFailure;
  Completer<void>? addGate;
  Completer<void>? updateGate;

  int addCount = 0;
  int updateCount = 0;
  Object? lastAdded;
  Object? lastUpdated;

  @override
  Future<Result<VaultData>> getVault() {
    throw UnimplementedError();
  }

  @override
  Future<Result<Object>> getItemById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> addItem(Object item) async {
    addCount++;
    lastAdded = item;
    final gate = addGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = addFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> updateItem(Object item) async {
    updateCount++;
    lastUpdated = item;
    final gate = updateGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = updateFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteItem(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> setItemPinned({
    required String id,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }
}
