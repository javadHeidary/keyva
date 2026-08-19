import 'dart:async';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
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
      categories: current.categories,
    );
    return const Success(null);
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
      categories: current.categories,
    );
  }
}
