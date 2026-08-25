import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/category/model/category_defaults.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_ui_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeVaultOperationService operations;
  late VaultHomeViewModel viewModel;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
    String username = 'keep-this-user',
    String? website = 'https://mail.test',
    String? notes,
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: username,
      password: 'keep-this-password',
      website: website,
      notes: notes,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({
    String id = 'card-1',
    String title = 'Travel',
    String cardHolder = 'Nima Karimi',
    String bankName = 'Saman',
  }) {
    return BankCardItem(
      id: id,
      title: title,
      cardNumber: '6219861234567890',
      cardHolder: cardHolder,
      expiryDate: '06/30',
      cvv: '321',
      bankName: bankName,
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

  VaultData emptyVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  VaultData populatedVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: [category()],
    );
  }

  setUp(() {
    operations = _FakeVaultOperationService();
    viewModel = VaultHomeViewModel(operations: operations);
  });

  group('loading', () {
    test('starts in the initial state', () {
      expect(viewModel.status.value, VaultUiStatus.initial);
      expect(viewModel.vault.value, isNull);
      expect(viewModel.visibleItems, isEmpty);
      expect(viewModel.errorMessage.value, isNull);
    });

    test('sets loading then loaded when the vault has items', () async {
      operations.vault = populatedVault();
      operations.getVaultGate = Completer<void>();

      final future = viewModel.loadVault();
      expect(viewModel.status.value, VaultUiStatus.loading);

      operations.getVaultGate!.complete();
      await future;

      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.vault.value, operations.vault);
      expect(viewModel.visibleItems, [login(), card(), note(), category()]);
      expect(viewModel.errorMessage.value, isNull);
    });

    test('sets empty when the vault has no items', () async {
      operations.vault = emptyVault();

      await viewModel.loadVault();

      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(viewModel.visibleItems, isEmpty);
    });

    test('stays empty when the vault only has categories', () async {
      operations.vault = VaultData(
        version: VaultData.currentVersion,
        logins: const [],
        bankCards: const [],
        secureNotes: const [],
        categories: CategoryDefaults.items,
      );

      await viewModel.loadVault();

      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(viewModel.visibleItems, isEmpty);
    });

    test('maps AuthenticationFailure to a presentation error', () async {
      operations.getVaultFailure = const AuthenticationFailure();

      await viewModel.loadVault();

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Unable to unlock your vault.');
      expect(viewModel.vault.value, isNull);
    });

    test('maps DatabaseFailure to a presentation error', () async {
      operations.getVaultFailure = const DatabaseFailure();

      await viewModel.loadVault();

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Database operation failed');
    });

    test('refresh reloads the current vault', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();

      operations.vault = emptyVault();
      await viewModel.refreshVault();

      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(operations.getVaultCount, 2);
    });
  });

  group('search', () {
    test('returns matching items in vault collection order', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();

      viewModel.searchItems('mail');

      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.visibleItems, [login()]);
      expect(viewModel.searchQuery.value, 'mail');
    });

    test('matches logins, cards, notes, and categories', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();

      viewModel.searchItems('work');
      expect(viewModel.visibleItems, [category()]);

      viewModel.searchItems('saman');
      expect(viewModel.visibleItems, [card()]);

      viewModel.searchItems('building-code');
      expect(viewModel.visibleItems, [note()]);
    });

    test('leaves loaded state with no items when nothing matches', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();

      viewModel.searchItems('no-such-item');

      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.visibleItems, isEmpty);
    });

    test('empty query restores all items', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();
      viewModel.searchItems('mail');

      viewModel.searchItems('   ');

      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.visibleItems, [login(), card(), note(), category()]);
    });

    test('does not mutate the persisted vault', () async {
      final vault = populatedVault();
      operations.vault = vault;
      await viewModel.loadVault();

      viewModel.searchItems('mail');
      viewModel.searchItems('');

      expect(operations.persistCount, 0);
      expect(operations.lastDeletedId, isNull);
      expect(operations.vault, same(vault));
      expect(vault.logins, [login()]);
      expect(vault.bankCards, [card()]);
      expect(vault.secureNotes, [note()]);
      expect(vault.categories, [category()]);
    });

    test('stays empty when searching an empty vault', () async {
      operations.vault = emptyVault();
      await viewModel.loadVault();

      viewModel.searchItems('mail');

      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(viewModel.visibleItems, isEmpty);
      expect(operations.persistCount, 0);
    });

    test('re-applies the current query after reload', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();
      viewModel.searchItems('mail');

      await viewModel.refreshVault();

      expect(viewModel.visibleItems, [login()]);
    });
  });

  group('addItem', () {
    test('persists the item and refreshes the vault', () async {
      operations.vault = emptyVault();
      await viewModel.loadVault();

      final created = login(id: 'login-new', title: 'Example Gmail');
      final result = await viewModel.addItem(created);

      expect(result.isSuccess, isTrue);
      expect(operations.lastAdded, created);
      expect(operations.persistCount, 1);
      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.visibleItems, [created]);
    });

    test('does not refresh when add fails', () async {
      operations.vault = emptyVault();
      await viewModel.loadVault();
      operations.addFailure = const DatabaseFailure();

      final result = await viewModel.addItem(login(id: 'login-new'));

      expect(result.isFailure, isTrue);
      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(viewModel.visibleItems, isEmpty);
      expect(operations.vault?.logins, isEmpty);
    });
  });

  group('delete', () {
    test('sets submitting then refreshes after a successful delete', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();
      operations.deleteGate = Completer<void>();

      final future = viewModel.deleteItem('login-1');
      expect(viewModel.status.value, VaultUiStatus.submitting);
      expect(viewModel.visibleItems, isNotEmpty);

      operations.deleteGate!.complete();
      await future;

      expect(operations.lastDeletedId, 'login-1');
      expect(operations.persistCount, 1);
      expect(viewModel.status.value, VaultUiStatus.loaded);
      expect(viewModel.visibleItems, [card(), note(), category()]);
    });

    test('sets empty after deleting the last item', () async {
      operations.vault = VaultData(
        version: VaultData.currentVersion,
        logins: [login()],
        bankCards: const [],
        secureNotes: const [],
        categories: const [],
      );
      await viewModel.loadVault();

      await viewModel.deleteItem('login-1');

      expect(viewModel.status.value, VaultUiStatus.empty);
      expect(viewModel.visibleItems, isEmpty);
    });

    test('keeps previous items when delete fails', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();
      operations.deleteFailure = const ValidationFailure();

      await viewModel.deleteItem('login-1');

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Vault data is invalid');
      expect(viewModel.visibleItems, [login(), card(), note(), category()]);
      expect(viewModel.vault.value, operations.vault);
    });

    test('maps CryptoFailure to a presentation error', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();
      operations.deleteFailure = const CryptoFailure();

      await viewModel.deleteItem('login-1');

      expect(viewModel.status.value, VaultUiStatus.error);
      expect(viewModel.errorMessage.value, 'Cryptographic operation failed');
    });
  });

  group('pin order', () {
    test(
      'shows pinned items before unpinned items and keeps relative order',
      () async {
        final unpinnedLogin = login();
        final pinnedLogin = login(
          id: 'login-2',
          title: 'Pinned Mail',
        ).copyWith(isPinned: true);
        final pinnedCard = card().copyWith(isPinned: true);
        operations.vault = VaultData(
          version: VaultData.currentVersion,
          logins: [unpinnedLogin, pinnedLogin],
          bankCards: [pinnedCard],
          secureNotes: [note()],
          categories: [category()],
        );

        await viewModel.loadVault();

        expect(viewModel.visibleItems, [
          pinnedLogin,
          pinnedCard,
          unpinnedLogin,
          note(),
          category(),
        ]);
        expect(viewModel.visibleItems.whereType<LoginItem>().toList(), [
          pinnedLogin,
          unpinnedLogin,
        ]);
      },
    );

    test('setItemPinned reloads pin-first order', () async {
      operations.vault = populatedVault();
      await viewModel.loadVault();

      final result = await viewModel.setItemPinned(
        id: 'note-1',
        isPinned: true,
      );

      expect(result, isA<Success<void>>());
      expect(viewModel.visibleItems.first, note().copyWith(isPinned: true));
    });
  });
}

class _FakeVaultOperationService implements VaultOperationService {
  VaultData? vault;
  AppFailure? getVaultFailure;
  AppFailure? addFailure;
  AppFailure? deleteFailure;
  Completer<void>? getVaultGate;
  Completer<void>? deleteGate;

  int getVaultCount = 0;
  int persistCount = 0;
  String? lastDeletedId;
  Object? lastAdded;

  @override
  Future<Result<VaultData>> getVault() async {
    getVaultCount++;
    final gate = getVaultGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = getVaultFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final current = vault;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(current);
  }

  @override
  Future<Result<Object>> getItemById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> addItem(Object item) async {
    persistCount++;
    lastAdded = item;
    final failure = addFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final current =
        vault ??
        VaultData(
          version: VaultData.currentVersion,
          logins: const [],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        );
    vault = VaultData(
      version: current.version,
      logins: [...current.logins, if (item is LoginItem) item],
      bankCards: [...current.bankCards, if (item is BankCardItem) item],
      secureNotes: [...current.secureNotes, if (item is SecureNoteItem) item],
      categories: [...current.categories, if (item is CategoryItem) item],
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> updateItem(Object item) {
    persistCount++;
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deleteItem(String id) async {
    persistCount++;
    lastDeletedId = id;
    final gate = deleteGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = deleteFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    final current = vault;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }
    vault = VaultData(
      version: current.version,
      logins: [
        for (final item in current.logins)
          if (item.id != id) item,
      ],
      bankCards: [
        for (final item in current.bankCards)
          if (item.id != id) item,
      ],
      secureNotes: [
        for (final item in current.secureNotes)
          if (item.id != id) item,
      ],
      categories: [
        for (final item in current.categories)
          if (item.id != id) item,
      ],
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> setItemPinned({
    required String id,
    required bool isPinned,
  }) async {
    final current = vault;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }
    Object? found;
    for (final item in [
      ...current.logins,
      ...current.bankCards,
      ...current.secureNotes,
    ]) {
      if (item is LoginItem && item.id == id) found = item;
      if (item is BankCardItem && item.id == id) found = item;
      if (item is SecureNoteItem && item.id == id) found = item;
    }
    if (found == null) {
      return const FailureResult(ValidationFailure());
    }
    final currentlyPinned = switch (found) {
      LoginItem login => login.isPinned,
      BankCardItem card => card.isPinned,
      SecureNoteItem note => note.isPinned,
      _ => false,
    };
    if (currentlyPinned == isPinned) {
      return const Success(null);
    }
    if (isPinned && current.pinnedItemCount >= VaultData.maxPinnedItems) {
      return const FailureResult(PinLimitFailure());
    }
    persistCount++;
    final updated = switch (found) {
      LoginItem login => login.copyWith(isPinned: isPinned),
      BankCardItem card => card.copyWith(isPinned: isPinned),
      SecureNoteItem note => note.copyWith(isPinned: isPinned),
      _ => found,
    };
    vault = VaultData(
      version: current.version,
      logins: [
        for (final login in current.logins)
          if (updated is LoginItem && login.id == updated.id)
            updated
          else
            login,
      ],
      bankCards: [
        for (final card in current.bankCards)
          if (updated is BankCardItem && card.id == updated.id)
            updated
          else
            card,
      ],
      secureNotes: [
        for (final note in current.secureNotes)
          if (updated is SecureNoteItem && note.id == updated.id)
            updated
          else
            note,
      ],
      categories: current.categories,
    );
    return const Success(null);
  }
}
