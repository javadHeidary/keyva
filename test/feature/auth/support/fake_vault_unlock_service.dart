import 'dart:async';
import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';

class FakeVaultUnlockService implements VaultUnlockService {
  FakeVaultUnlockService({required this.session});

  final SessionService session;
  Completer<void>? unlockGate;
  AppFailure? unlockFailure;
  int unlockCount = 0;
  int lockCount = 0;
  String? lastUserId;
  String? lastPassword;

  @override
  Future<Result<void>> unlock({
    required String userId,
    required String masterPassword,
  }) async {
    unlockCount++;
    lastUserId = userId;
    lastPassword = masterPassword;
    final gate = unlockGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = unlockFailure;
    if (failure != null) {
      session.clear();
      return FailureResult(failure);
    }
    session.setAuthenticated(
      userId: userId,
      username: 'test',
      vaultKey: Uint8List(32),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> lock() async {
    lockCount++;
    session.clear();
    return const Success(null);
  }
}
