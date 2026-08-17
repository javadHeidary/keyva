import 'dart:typed_data';

import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/exceptions/result.dart';

abstract interface class CryptoService {
  Uint8List generateSecureBytes(int length);

  Future<Result<Uint8List>> deriveKey({
    required String masterPassword,
    required Uint8List salt,
    required KdfParameters parameters,
  });

  Future<Result<EncryptedPayload>> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  });

  Future<Result<Uint8List>> decrypt({
    required EncryptedPayload payload,
    required Uint8List key,
  });
}
