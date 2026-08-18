import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late CryptoService crypto;
  late SessionService session;
  late VaultRepository repository;
  late VaultSerializer serializer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_vault_ser_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    crypto = CryptoServiceImpl();
    session = SessionServiceImpl();
    repository = VaultRepositoryImpl(
      vaults: HiveVaultDataSource(database!),
      crypto: crypto,
      session: session,
    );
    serializer = VaultSerializerImpl();
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'VaultData survives serialize, encrypted Hive save, load, and deserialize',
    () async {
      session.setAuthenticated(
        userId: 'user-1',
        username: 'علی',
        vaultKey: crypto.generateSecureBytes(SecurityConstants.vaultKeyLength),
      );

      final createdAt = DateTime.utc(2026, 5, 1, 10);
      final updatedAt = DateTime.utc(2026, 5, 2, 11);
      final original = VaultData(
        version: VaultData.currentVersion,
        categories: [
          CategoryItem(
            id: 'cat-mail',
            name: 'Mail',
            icon: 'inbox',
            createdAt: createdAt,
          ),
        ],
        logins: [
          LoginItem(
            id: 'login-mail',
            title: 'Mail',
            username: 'keep-this-user',
            password: 'keep-this-password',
            website: 'https://mail.test',
            notes: null,
            categoryId: 'cat-mail',
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ],
        bankCards: [
          BankCardItem(
            id: 'card-mail',
            title: 'Travel',
            cardNumber: '6219861234567890',
            cardHolder: 'Nima Karimi',
            expiryDate: '06/30',
            cvv: '321',
            bankName: 'Saman',
            notes: null,
            categoryId: 'cat-mail',
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ],
        secureNotes: [
          SecureNoteItem(
            id: 'note-mail',
            title: 'Gate',
            content: 'building-code-42',
            categoryId: 'cat-mail',
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ],
      );

      final plaintext = _expectSuccess(await serializer.serialize(original));
      _expectSuccess(await repository.saveVaultData(plaintext));
      final loaded = _expectSuccess(await repository.loadVaultData());
      expect(loaded, isNotNull);
      final restored = _expectSuccess(await serializer.deserialize(loaded!));

      expect(restored, original);
      expect(
        _containsSequence(
          database!.vaults.get('user-1')!.ciphertext,
          plaintext,
        ),
        isFalse,
      );
    },
  );
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

bool _containsSequence(Uint8List haystack, Uint8List needle) {
  if (needle.isEmpty || haystack.length < needle.length) {
    return false;
  }
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return true;
    }
  }
  return false;
}
