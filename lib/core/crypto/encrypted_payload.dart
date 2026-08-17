import 'dart:typed_data';

class EncryptedPayload {
  const EncryptedPayload({
    required this.version,
    required this.nonce,
    required this.ciphertext,
    required this.authenticationTag,
  });

  final int version;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final Uint8List authenticationTag;
}
