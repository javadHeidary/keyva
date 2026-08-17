import 'dart:typed_data';

import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';

class UserRecord {
  const UserRecord({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    required this.kdfSalt,
    required this.kdfParameters,
    required this.wrappedVaultKey,
    required this.securitySettings,
  });

  final String id;
  final String username;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Uint8List kdfSalt;
  final KdfParameters kdfParameters;
  final WrappedVaultKey wrappedVaultKey;
  final SecuritySettings securitySettings;
}
