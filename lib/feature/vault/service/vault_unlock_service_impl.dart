import 'dart:typed_data';

import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

class VaultUnlockServiceImpl implements VaultUnlockService {
  VaultUnlockServiceImpl({
    required AuthRepository auth,
    required VaultRepository vaults,
    required VaultSerializer serializer,
    required VaultSession vaultSession,
    PinService? pin,
    BiometricService? biometric,
  }) : _auth = auth,
       _vaults = vaults,
       _serializer = serializer,
       _vaultSession = vaultSession,
       _pin = pin,
       _biometric = biometric;

  final AuthRepository _auth;
  final VaultRepository _vaults;
  final VaultSerializer _serializer;
  final VaultSession _vaultSession;
  final PinService? _pin;
  final BiometricService? _biometric;

  static const _biometricUnlockReason = 'برای باز کردن گاوصندوق';

  @override
  Future<Result<void>> unlock({
    required String userId,
    required String masterPassword,
  }) async {
    final authenticated = await _auth.authenticate(
      userId: userId,
      masterPassword: masterPassword,
    );
    if (authenticated is FailureResult<UserRecord>) {
      await _vaultSession.lock();
      return FailureResult(authenticated.failure);
    }
    await _pin?.resetFailedAttempts(userId);
    return _openVault();
  }

  @override
  Future<Result<void>> unlockWithPin({
    required String userId,
    required String pin,
  }) async {
    final pinService = _pin;
    if (pinService == null) {
      return _failClosed(const AuthenticationFailure());
    }
    final unwrapped = await pinService.unwrapVaultKey(userId: userId, pin: pin);
    if (unwrapped is FailureResult<Uint8List>) {
      return _failClosed(unwrapped.failure);
    }
    return _openSessionAndVault(
      userId: userId,
      vaultKey: (unwrapped as Success<Uint8List>).data,
    );
  }

  @override
  Future<Result<void>> unlockWithBiometric({required String userId}) async {
    final biometric = _biometric;
    if (biometric == null) {
      return _failClosed(const AuthenticationFailure());
    }
    final unwrapped = await biometric.unwrapVaultKey(
      userId: userId,
      localizedReason: _biometricUnlockReason,
    );
    if (unwrapped is FailureResult<Uint8List>) {
      if (unwrapped.failure is BiometricCancelledFailure) {
        return FailureResult(unwrapped.failure);
      }
      return _failClosed(unwrapped.failure);
    }
    return _openSessionAndVault(
      userId: userId,
      vaultKey: (unwrapped as Success<Uint8List>).data,
    );
  }

  @override
  Future<Result<void>> lock() async {
    await _vaultSession.lock();
    return _auth.logout();
  }

  Future<Result<void>> _openSessionAndVault({
    required String userId,
    required Uint8List vaultKey,
  }) async {
    final opened = await _auth.openSession(userId: userId, vaultKey: vaultKey);
    if (opened is FailureResult<UserRecord>) {
      return _failClosed(opened.failure);
    }
    return _openVault();
  }

  Future<Result<void>> _openVault() async {
    final loaded = await _vaults.loadVaultData();
    if (loaded is FailureResult<Uint8List?>) {
      return _failClosed(loaded.failure);
    }
    final plaintext = (loaded as Success<Uint8List?>).data;

    late final VaultData vaultData;
    if (plaintext == null) {
      vaultData = VaultData(
        version: VaultData.currentVersion,
        logins: const [],
        bankCards: const [],
        secureNotes: const [],
        categories: const [],
      );
    } else {
      final deserialized = await _serializer.deserialize(plaintext);
      if (deserialized is FailureResult<VaultData>) {
        return _failClosed(deserialized.failure);
      }
      vaultData = (deserialized as Success<VaultData>).data;
    }

    final unlocked = await _vaultSession.unlock(vaultData);
    if (unlocked is FailureResult<void>) {
      return _failClosed(unlocked.failure);
    }
    return unlocked;
  }

  Future<Result<void>> _failClosed(AppFailure failure) async {
    await _vaultSession.lock();
    await _auth.logout();
    return FailureResult(failure);
  }
}
