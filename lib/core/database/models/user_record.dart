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

  UserRecord copyWith({
    String? id,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? kdfSalt,
    KdfParameters? kdfParameters,
    WrappedVaultKey? wrappedVaultKey,
    SecuritySettings? securitySettings,
  }) {
    return UserRecord(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kdfSalt: kdfSalt ?? this.kdfSalt,
      kdfParameters: kdfParameters ?? this.kdfParameters,
      wrappedVaultKey: wrappedVaultKey ?? this.wrappedVaultKey,
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }
}
