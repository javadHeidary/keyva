import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late VaultDataSource vaults;
  late CryptoService crypto;
  late SessionService session;
  late AuthRepository auth;
  late VaultRepository repository;
  late VaultSerializer serializer;
  late VaultSession vaultSession;
  late VaultUnlockService unlockService;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const masterPassword = 'correct-master-password';
  const loginPassword = 'keep-this-password';
  const cardNumber = '6219861234567890';
  const cvv = '321';
  const noteContent = 'building-code-42';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_vault_unlock_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    vaults = HiveVaultDataSource(database!);
    crypto = CryptoServiceImpl();
    session = SessionServiceImpl();
    auth = AuthRepositoryImpl(
      users: HiveUserDataSource(database!),
      crypto: crypto,
      keys: KeyManagementServiceImpl(crypto),
      session: session,
      database: database!,
      vaults: vaults,
    );
    repository = VaultRepositoryImpl(
      vaults: vaults,
      crypto: crypto,
      session: session,
    );
    serializer = VaultSerializerImpl();
    vaultSession = VaultSessionImpl();
    unlockService = VaultUnlockServiceImpl(
      auth: auth,
      vaults: repository,
      serializer: serializer,
      vaultSession: vaultSession,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<UserRecord> createUser() async {
    return _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: masterPassword),
    );
  }

  Future<Uint8List> persistVault(UserRecord user, VaultData vault) async {
    _expectSuccess(
      await auth.authenticate(userId: user.id, masterPassword: masterPassword),
    );
    final plaintext = _expectSuccess(await serializer.serialize(vault));
    _expectSuccess(await repository.saveVaultData(plaintext));
    _expectSuccess(await auth.logout());
    return plaintext;
  }

  test('session starts empty and locked', () {
    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
  });

  test('successful unlock restores the original VaultData', () async {
    final user = await createUser();
    final original = _sampleVault();
    await persistVault(user, original);

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    expect(vaultSession.isUnlocked, isTrue);
    expect(vaultSession.vaultData, original);
    expect(session.isAuthenticated, isTrue);
    expect(session.vaultKey, isNotNull);
  }, timeout: kdfTimeout);

  test('wrong password fails without unlocking the session', () async {
    final user = await createUser();
    await persistVault(user, _sampleVault());

    _expectFailure<AuthenticationFailure>(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: 'wrong-master-password',
      ),
      forbidden: const [
        masterPassword,
        'wrong-master-password',
        loginPassword,
        cardNumber,
        cvv,
        noteContent,
      ],
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('corrupted encrypted vault fails and stays locked', () async {
    final user = await createUser();
    await persistVault(user, _sampleVault());

    final stored = _expectSuccess(await vaults.findByUserId(user.id))!;
    final tampered = Uint8List.fromList(stored.ciphertext);
    tampered[0] = tampered[0] ^ 0xFF;
    _expectSuccess(
      await vaults.update(
        VaultRecord(
          userId: stored.userId,
          formatVersion: stored.formatVersion,
          nonce: stored.nonce,
          ciphertext: tampered,
          updatedAt: stored.updatedAt,
        ),
      ),
    );

    _expectFailure<VaultDecryptionFailure>(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
      forbidden: const [loginPassword, cardNumber, cvv, noteContent],
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('invalid decrypted JSON fails with ValidationFailure', () async {
    final user = await createUser();
    _expectSuccess(
      await auth.authenticate(userId: user.id, masterPassword: masterPassword),
    );
    _expectSuccess(
      await repository.saveVaultData(
        Uint8List.fromList(utf8.encode('{"not":"a-vault"}')),
      ),
    );
    _expectSuccess(await auth.logout());

    _expectFailure<ValidationFailure>(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
      forbidden: const [
        '{"not":"a-vault"}',
        loginPassword,
        cardNumber,
        'FormatException',
      ],
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('unsupported VaultData version fails with ValidationFailure', () async {
    final user = await createUser();
    final json = jsonDecode(
      utf8.decode(_expectSuccess(await serializer.serialize(_emptyVault()))),
    ) as Map<String, dynamic>;
    json['version'] = 99;
    _expectSuccess(
      await auth.authenticate(userId: user.id, masterPassword: masterPassword),
    );
    _expectSuccess(
      await repository.saveVaultData(
        Uint8List.fromList(utf8.encode(jsonEncode(json))),
      ),
    );
    _expectSuccess(await auth.logout());

    _expectFailure<ValidationFailure>(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
      forbidden: const ['99', loginPassword, cardNumber],
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('missing vault unlocks an in-memory vault with default categories', () async {
    final user = await createUser();

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    expect(vaultSession.isUnlocked, isTrue);
    expect(vaultSession.vaultData, VaultData.initial());
    expect(
      vaultSession.vaultData!.categories.map((category) => category.name),
      ['شخصی', 'مالی', 'کاری'],
    );
    expect(vaultSession.vaultData!.version, VaultData.currentVersion);
    expect(_expectSuccess(await vaults.findByUserId(user.id)), isNull);
  }, timeout: kdfTimeout);

  test('missing vault unlock does not duplicate default categories', () async {
    final user = await createUser();

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );
    _expectSuccess(await unlockService.lock());
    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    expect(vaultSession.vaultData, VaultData.initial());
    expect(vaultSession.vaultData!.categories, hasLength(3));
    expect(_expectSuccess(await vaults.findByUserId(user.id)), isNull);
  }, timeout: kdfTimeout);

  test('persisted vault with empty categories is not backfilled', () async {
    final user = await createUser();
    await persistVault(user, _emptyVault());

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    expect(vaultSession.vaultData!.categories, isEmpty);
  }, timeout: kdfTimeout);

  test('failed unlock after a successful unlock leaves the session locked', () async {
    final user = await createUser();
    await persistVault(user, _sampleVault());

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );
    expect(vaultSession.isUnlocked, isTrue);

    _expectFailure<AuthenticationFailure>(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: 'wrong-master-password',
      ),
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('lock clears vault data and the authenticated VaultKey', () async {
    final user = await createUser();
    await persistVault(user, _sampleVault());
    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );
    final vaultKey = session.vaultKey!;

    _expectSuccess(await unlockService.lock());

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(vaultKey, Uint8List(vaultKey.length));
  }, timeout: kdfTimeout);

  test('plaintext vault bytes are not stored in Hive', () async {
    final user = await createUser();
    final original = _sampleVault();
    final plaintext = await persistVault(user, original);

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    final stored = _expectSuccess(await vaults.findByUserId(user.id))!;
    expect(_containsSequence(stored.ciphertext, plaintext), isFalse);
    expect(_containsSequence(stored.ciphertext, utf8.encode(loginPassword)), isFalse);
    expect(_containsSequence(stored.ciphertext, utf8.encode(cardNumber)), isFalse);
    expect(_containsSequence(stored.ciphertext, utf8.encode(cvv)), isFalse);
    expect(_containsSequence(stored.ciphertext, utf8.encode(noteContent)), isFalse);
  }, timeout: kdfTimeout);

  test('VaultKey is not serialized into VaultData', () async {
    final user = await createUser();
    await persistVault(user, _sampleVault());

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );

    final serialized = _expectSuccess(
      await serializer.serialize(vaultSession.vaultData!),
    );
    final json = jsonDecode(utf8.decode(serialized)) as Map<String, dynamic>;
    expect(json.containsKey('vaultKey'), isFalse);
    expect(json.keys, [
      'version',
      'logins',
      'bankCards',
      'secureNotes',
      'categories',
      'imageFolders',
      'images',
    ]);
    expect(_containsSequence(serialized, session.vaultKey!), isFalse);
  }, timeout: kdfTimeout);
}

VaultData _emptyVault() {
  return VaultData(
    version: VaultData.currentVersion,
    logins: const [],
    bankCards: const [],
    secureNotes: const [],
    categories: const [],
  );
}

VaultData _sampleVault() {
  final createdAt = DateTime.utc(2026, 5, 1, 10);
  final updatedAt = DateTime.utc(2026, 5, 2, 11);
  return VaultData(
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
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectFailure<F extends AppFailure>(
  Result<dynamic> result, {
  List<String> forbidden = const [],
}) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<F>());
  expect(failure.message, isNot(contains('SecretBox')));
  expect(failure.message, isNot(contains('GCM')));
  expect(failure.message, isNot(contains('HiveError')));
  expect(failure.message, isNot(contains('FormatException')));
  for (final value in forbidden) {
    expect(failure.message, isNot(contains(value)));
  }
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
