// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class UserRecordAdapter extends TypeAdapter<UserRecord> {
  @override
  final typeId = 0;

  @override
  UserRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserRecord(
      id: fields[0] as String,
      username: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      kdfSalt: fields[4] as Uint8List,
      kdfParameters: fields[5] as KdfParameters,
      wrappedVaultKey: fields[6] as WrappedVaultKey,
      securitySettings: fields[7] as SecuritySettings,
    );
  }

  @override
  void write(BinaryWriter writer, UserRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.kdfSalt)
      ..writeByte(5)
      ..write(obj.kdfParameters)
      ..writeByte(6)
      ..write(obj.wrappedVaultKey)
      ..writeByte(7)
      ..write(obj.securitySettings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KdfParametersAdapter extends TypeAdapter<KdfParameters> {
  @override
  final typeId = 1;

  @override
  KdfParameters read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KdfParameters(
      algorithm: fields[0] as String,
      memoryCost: (fields[1] as num).toInt(),
      timeCost: (fields[2] as num).toInt(),
      parallelism: (fields[3] as num).toInt(),
      outputLength: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, KdfParameters obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.algorithm)
      ..writeByte(1)
      ..write(obj.memoryCost)
      ..writeByte(2)
      ..write(obj.timeCost)
      ..writeByte(3)
      ..write(obj.parallelism)
      ..writeByte(4)
      ..write(obj.outputLength);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KdfParametersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WrappedVaultKeyAdapter extends TypeAdapter<WrappedVaultKey> {
  @override
  final typeId = 2;

  @override
  WrappedVaultKey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WrappedVaultKey(
      version: (fields[0] as num).toInt(),
      nonce: fields[1] as Uint8List,
      ciphertext: fields[2] as Uint8List,
      authenticationTag: fields[3] as Uint8List,
    );
  }

  @override
  void write(BinaryWriter writer, WrappedVaultKey obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.nonce)
      ..writeByte(2)
      ..write(obj.ciphertext)
      ..writeByte(3)
      ..write(obj.authenticationTag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrappedVaultKeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SecuritySettingsAdapter extends TypeAdapter<SecuritySettings> {
  @override
  final typeId = 3;

  @override
  SecuritySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SecuritySettings(
      biometricEnabled: fields[0] as bool,
      pinEnabled: fields[1] as bool,
      autoLockTimeout: fields[2] as Duration,
      preventScreenshots: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SecuritySettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.biometricEnabled)
      ..writeByte(1)
      ..write(obj.pinEnabled)
      ..writeByte(2)
      ..write(obj.autoLockTimeout)
      ..writeByte(3)
      ..write(obj.preventScreenshots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecuritySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VaultRecordAdapter extends TypeAdapter<VaultRecord> {
  @override
  final typeId = 4;

  @override
  VaultRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaultRecord(
      userId: fields[0] as String,
      formatVersion: (fields[1] as num).toInt(),
      nonce: fields[2] as Uint8List,
      ciphertext: fields[3] as Uint8List,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VaultRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.formatVersion)
      ..writeByte(2)
      ..write(obj.nonce)
      ..writeByte(3)
      ..write(obj.ciphertext)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
