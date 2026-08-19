import 'dart:typed_data';

import 'package:keyva/core/database/models/kdf_parameters.dart';

class BackupEnvelope {
  const BackupEnvelope({
    required this.formatVersion,
    required this.kdfSalt,
    required this.kdfParameters,
    required this.nonce,
    required this.ciphertext,
    required this.authenticationTag,
  });

  final int formatVersion;
  final Uint8List kdfSalt;
  final KdfParameters kdfParameters;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final Uint8List authenticationTag;
}
