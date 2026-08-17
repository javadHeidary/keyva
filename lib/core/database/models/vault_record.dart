import 'dart:typed_data';

class VaultRecord {
  const VaultRecord({
    required this.userId,
    required this.formatVersion,
    required this.nonce,
    required this.ciphertext,
    required this.updatedAt,
  });

  final String userId;
  final int formatVersion;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final DateTime updatedAt;
}
