import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';

class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl({
    required VaultDataSource vaults,
    required CryptoService crypto,
    required SessionService session,
  }) : _vaults = vaults,
       _crypto = crypto,
       _session = session;

  final VaultDataSource _vaults;
  final CryptoService _crypto;
  final SessionService _session;

  @override
  Future<Result<Uint8List?>> loadVaultData() async {
    final session = _requireAuthenticatedSession();
    if (session is FailureResult<_AuthenticatedVaultSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_AuthenticatedVaultSession>).data;

    final loaded = await _vaults.findByUserId(authenticated.userId);
    if (loaded is FailureResult<VaultRecord?>) {
      return FailureResult(loaded.failure);
    }
    final record = (loaded as Success<VaultRecord?>).data;
    if (record == null) {
      return const Success(null);
    }

    final payload = _payloadFromRecord(record);
    if (payload == null) {
      return const FailureResult(CryptoFailure());
    }

    final decrypted = await _crypto.decrypt(
      payload: payload,
      key: authenticated.vaultKey,
    );
    if (decrypted is FailureResult<Uint8List>) {
      return FailureResult(decrypted.failure);
    }
    return Success((decrypted as Success<Uint8List>).data);
  }

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) async {
    final session = _requireAuthenticatedSession();
    if (session is FailureResult<_AuthenticatedVaultSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_AuthenticatedVaultSession>).data;

    final encrypted = await _crypto.encrypt(
      plaintext: plaintext,
      key: authenticated.vaultKey,
    );
    if (encrypted is FailureResult<EncryptedPayload>) {
      return FailureResult(encrypted.failure);
    }
    final payload = (encrypted as Success<EncryptedPayload>).data;
    if (!_isValidPayload(payload)) {
      return const FailureResult(CryptoFailure());
    }

    final record = VaultRecord(
      userId: authenticated.userId,
      formatVersion: SecurityConstants.vaultEncryptionVersion,
      nonce: payload.nonce,
      ciphertext: _combineCiphertextAndTag(payload),
      updatedAt: DateTime.now(),
    );

    final existing = await _vaults.findByUserId(authenticated.userId);
    if (existing is FailureResult<VaultRecord?>) {
      return FailureResult(existing.failure);
    }
    if ((existing as Success<VaultRecord?>).data == null) {
      return _vaults.create(record);
    }
    return _vaults.update(record);
  }

  @override
  Future<Result<void>> deleteVault() async {
    final session = _requireAuthenticatedSession();
    if (session is FailureResult<_AuthenticatedVaultSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_AuthenticatedVaultSession>).data;
    return _vaults.delete(authenticated.userId);
  }

  Result<_AuthenticatedVaultSession> _requireAuthenticatedSession() {
    final current = _session.current;
    final vaultKey = _session.vaultKey;
    if (!_session.isAuthenticated || current == null || vaultKey == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(
      _AuthenticatedVaultSession(userId: current.userId, vaultKey: vaultKey),
    );
  }

  EncryptedPayload? _payloadFromRecord(VaultRecord record) {
    if (record.formatVersion != SecurityConstants.vaultEncryptionVersion) {
      return null;
    }
    if (record.nonce.length != SecurityConstants.nonceLength) {
      return null;
    }
    if (record.ciphertext.length < SecurityConstants.authenticationTagLength) {
      return null;
    }

    final splitAt =
        record.ciphertext.length - SecurityConstants.authenticationTagLength;
    return EncryptedPayload(
      version: record.formatVersion,
      nonce: record.nonce,
      ciphertext: Uint8List.sublistView(record.ciphertext, 0, splitAt),
      authenticationTag: Uint8List.sublistView(record.ciphertext, splitAt),
    );
  }

  bool _isValidPayload(EncryptedPayload payload) {
    return payload.version == SecurityConstants.vaultEncryptionVersion &&
        payload.nonce.length == SecurityConstants.nonceLength &&
        payload.authenticationTag.length ==
            SecurityConstants.authenticationTagLength;
  }

  Uint8List _combineCiphertextAndTag(EncryptedPayload payload) {
    final combined = Uint8List(
      payload.ciphertext.length + payload.authenticationTag.length,
    );
    combined.setAll(0, payload.ciphertext);
    combined.setAll(payload.ciphertext.length, payload.authenticationTag);
    return combined;
  }
}

class _AuthenticatedVaultSession {
  const _AuthenticatedVaultSession({
    required this.userId,
    required this.vaultKey,
  });

  final String userId;
  final Uint8List vaultKey;
}
