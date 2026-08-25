import 'dart:async';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';

class FakeVaultOperationService implements VaultOperationService {
  VaultData? vault;
  AppFailure? getVaultFailure;
  AppFailure? addFailure;
  AppFailure? updateFailure;
  AppFailure? deleteFailure;
  Completer<void>? getVaultGate;
  Completer<void>? addGate;
  Completer<void>? updateGate;
  Completer<void>? deleteGate;

  int getVaultCount = 0;
  int addCount = 0;
  int updateCount = 0;
  int persistCount = 0;
  String? lastDeletedId;
  Object? lastAdded;
  Object? lastUpdated;

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
    addCount++;
    persistCount++;
    lastAdded = item;
    final gate = addGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = addFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    _insert(item);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateItem(Object item) async {
    updateCount++;
    persistCount++;
    lastUpdated = item;
    final gate = updateGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = updateFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    _replace(item);
    return const Success(null);
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
    final deletingFolder = current.imageFolders.any((folder) => folder.id == id);
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
      imageFolders: [
        for (final item in current.imageFolders)
          if (item.id != id) item,
      ],
      images: [
        for (final item in current.images)
          if (item.id != id && !(deletingFolder && item.folderId == id)) item,
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
    final found = _findPinnable(current, id);
    if (found == null) {
      return const FailureResult(ValidationFailure());
    }
    if (_itemIsPinned(found) == isPinned) {
      return const Success(null);
    }
    if (isPinned && current.pinnedItemCount >= VaultData.maxPinnedItems) {
      return const FailureResult(PinLimitFailure());
    }
    persistCount++;
    lastUpdated = switch (found) {
      LoginItem login => login.copyWith(isPinned: isPinned),
      BankCardItem card => card.copyWith(isPinned: isPinned),
      SecureNoteItem note => note.copyWith(isPinned: isPinned),
      ImageFolder folder => folder.copyWith(isPinned: isPinned),
      _ => found,
    };
    _replace(lastUpdated!);
    return const Success(null);
  }

  Object? _findPinnable(VaultData current, String id) {
    for (final login in current.logins) {
      if (login.id == id) return login;
    }
    for (final card in current.bankCards) {
      if (card.id == id) return card;
    }
    for (final note in current.secureNotes) {
      if (note.id == id) return note;
    }
    for (final folder in current.imageFolders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  bool _itemIsPinned(Object item) {
    return switch (item) {
      LoginItem login => login.isPinned,
      BankCardItem card => card.isPinned,
      SecureNoteItem note => note.isPinned,
      ImageFolder folder => folder.isPinned,
      _ => false,
    };
  }

  void _replace(Object item) {
    final current = vault;
    if (current == null) {
      _insert(item);
      return;
    }
    vault = VaultData(
      version: current.version,
      logins: [
        for (final login in current.logins)
          if (item is LoginItem && login.id == item.id) item else login,
      ],
      bankCards: [
        for (final card in current.bankCards)
          if (item is BankCardItem && card.id == item.id) item else card,
      ],
      secureNotes: [
        for (final note in current.secureNotes)
          if (item is SecureNoteItem && note.id == item.id) item else note,
      ],
      categories: [
        for (final category in current.categories)
          if (item is CategoryItem && category.id == item.id) item else category,
      ],
      imageFolders: [
        for (final folder in current.imageFolders)
          if (item is ImageFolder && folder.id == item.id) item else folder,
      ],
      images: [
        for (final image in current.images)
          if (item is ImageItem && image.id == item.id) item else image,
      ],
    );
  }

  void _insert(Object item) {
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
      logins: [
        ...current.logins,
        if (item is LoginItem) item,
      ],
      bankCards: [
        ...current.bankCards,
        if (item is BankCardItem) item,
      ],
      secureNotes: [
        ...current.secureNotes,
        if (item is SecureNoteItem) item,
      ],
      categories: [
        ...current.categories,
        if (item is CategoryItem) item,
      ],
      imageFolders: [
        ...current.imageFolders,
        if (item is ImageFolder) item,
      ],
      images: [
        ...current.images,
        if (item is ImageItem) item,
      ],
    );
  }
}
