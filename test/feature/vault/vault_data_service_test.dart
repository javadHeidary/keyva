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
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/category/model/category_defaults.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_data_service_impl.dart';
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
  late VaultDataService dataService;

  const kdfTimeout = Timeout(Duration(minutes: 2));
  const masterPassword = 'correct-master-password';
  const loginPassword = 'keep-this-password';
  const cardNumber = '6219861234567890';
  const cvv = '321';
  const noteContent = 'building-code-42';

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_vault_data_');
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
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: repository,
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

  Future<UserRecord> unlockEmptyVault() async {
    final user = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: masterPassword),
    );
    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );
    return user;
  }

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
    String password = loginPassword,
    String? categoryId,
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: 'keep-this-user',
      password: password,
      website: 'https://mail.test',
      notes: null,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({
    String id = 'card-1',
    String title = 'Travel',
  }) {
    return BankCardItem(
      id: id,
      title: title,
      cardNumber: cardNumber,
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: cvv,
      bankName: 'Saman',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note({
    String id = 'note-1',
    String title = 'Gate',
    String content = noteContent,
  }) {
    return SecureNoteItem(
      id: id,
      title: title,
      content: content,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category({
    String id = 'cat-1',
    String name = 'Mail',
  }) {
    return CategoryItem(
      id: id,
      name: name,
      icon: 'inbox',
      createdAt: createdAt,
    );
  }

  test('login add, update, delete, and invalid ids are rejected', () async {
    await unlockEmptyVault();
    final original = login();

    _expectSuccess(await dataService.addLogin(original));
    expect(vaultSession.vaultData!.logins, [original]);

    _expectFailure<ValidationFailure>(
      await dataService.addLogin(login(title: 'Other')),
      forbidden: const [loginPassword, cardNumber, cvv, noteContent],
    );
    expect(vaultSession.vaultData!.logins, [original]);

    final updated = login(title: 'Work Mail');
    _expectSuccess(await dataService.updateLogin(updated));
    expect(vaultSession.vaultData!.logins, [updated]);

    _expectFailure<ValidationFailure>(
      await dataService.updateLogin(login(id: 'missing')),
    );
    expect(vaultSession.vaultData!.logins, [updated]);

    _expectSuccess(await dataService.deleteLogin(updated.id));
    expect(vaultSession.vaultData!.logins, isEmpty);

    _expectFailure<ValidationFailure>(await dataService.deleteLogin('missing'));
    expect(vaultSession.vaultData!.logins, isEmpty);
  }, timeout: kdfTimeout);

  test('bank card add, update, delete, and invalid ids are rejected', () async {
    await unlockEmptyVault();
    final original = card();

    _expectSuccess(await dataService.addBankCard(original));
    expect(vaultSession.vaultData!.bankCards, [original]);

    _expectFailure<ValidationFailure>(
      await dataService.addBankCard(card(title: 'Other')),
      forbidden: const [loginPassword, cardNumber, cvv],
    );

    final updated = card(title: 'Salary');
    _expectSuccess(await dataService.updateBankCard(updated));
    expect(vaultSession.vaultData!.bankCards, [updated]);

    _expectFailure<ValidationFailure>(
      await dataService.updateBankCard(card(id: 'missing')),
    );

    _expectSuccess(await dataService.deleteBankCard(updated.id));
    expect(vaultSession.vaultData!.bankCards, isEmpty);

    _expectFailure<ValidationFailure>(
      await dataService.deleteBankCard('missing'),
    );
  }, timeout: kdfTimeout);

  test('secure note add, update, delete, and invalid ids are rejected', () async {
    await unlockEmptyVault();
    final original = note();

    _expectSuccess(await dataService.addSecureNote(original));
    expect(vaultSession.vaultData!.secureNotes, [original]);

    _expectFailure<ValidationFailure>(
      await dataService.addSecureNote(note(title: 'Other')),
      forbidden: const [noteContent],
    );

    final updated = note(title: 'Door', content: noteContent);
    _expectSuccess(await dataService.updateSecureNote(updated));
    expect(vaultSession.vaultData!.secureNotes, [updated]);

    _expectFailure<ValidationFailure>(
      await dataService.updateSecureNote(note(id: 'missing')),
    );

    _expectSuccess(await dataService.deleteSecureNote(updated.id));
    expect(vaultSession.vaultData!.secureNotes, isEmpty);

    _expectFailure<ValidationFailure>(
      await dataService.deleteSecureNote('missing'),
    );
  }, timeout: kdfTimeout);

  test('category add, update, delete, and invalid ids are rejected', () async {
    await unlockEmptyVault();
    final original = category();
    final linkedLogin = login(categoryId: original.id);

    _expectSuccess(await dataService.addCategory(original));
    _expectSuccess(await dataService.addLogin(linkedLogin));
    expect(vaultSession.vaultData!.categories, [
      ...CategoryDefaults.items,
      original,
    ]);

    _expectFailure<ValidationFailure>(
      await dataService.addCategory(category(name: 'Other')),
    );

    final updated = category(name: 'Work');
    _expectSuccess(await dataService.updateCategory(updated));
    expect(vaultSession.vaultData!.categories, [
      ...CategoryDefaults.items,
      updated,
    ]);

    _expectFailure<ValidationFailure>(
      await dataService.updateCategory(category(id: 'missing')),
    );

    _expectSuccess(await dataService.deleteCategory(updated.id));
    expect(vaultSession.vaultData!.categories, CategoryDefaults.items);
    expect(vaultSession.vaultData!.logins.single.categoryId, original.id);

    _expectFailure<ValidationFailure>(
      await dataService.deleteCategory('missing'),
    );
  }, timeout: kdfTimeout);

  test('mutations create a new immutable VaultData', () async {
    await unlockEmptyVault();
    final first = login();
    _expectSuccess(await dataService.addLogin(first));
    final before = vaultSession.vaultData!;

    final second = login(id: 'login-2');
    _expectSuccess(await dataService.addLogin(second));

    expect(before.logins, [first]);
    expect(vaultSession.vaultData!.logins, [first, second]);
    expect(identical(before, vaultSession.vaultData), isFalse);
    expect(
      () => vaultSession.vaultData!.logins.add(login(id: 'login-3')),
      throwsUnsupportedError,
    );
  }, timeout: kdfTimeout);

  test('mutations persist through lock and unlock', () async {
    final user = await unlockEmptyVault();
    _expectSuccess(await dataService.addLogin(login()));
    _expectSuccess(await dataService.addBankCard(card()));
    _expectSuccess(await dataService.addSecureNote(note()));
    _expectSuccess(await dataService.addCategory(category()));

    final stored = _expectSuccess(await vaults.findByUserId(user.id))!;
    final plaintext = _expectSuccess(
      await serializer.serialize(vaultSession.vaultData!),
    );
    expect(_containsSequence(stored.ciphertext, plaintext), isFalse);
    expect(
      _containsSequence(stored.ciphertext, utf8.encode(loginPassword)),
      isFalse,
    );
    expect(
      _containsSequence(stored.ciphertext, utf8.encode(cardNumber)),
      isFalse,
    );
    expect(_containsSequence(stored.ciphertext, utf8.encode(cvv)), isFalse);
    expect(
      _containsSequence(stored.ciphertext, utf8.encode(noteContent)),
      isFalse,
    );

    final json = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    expect(json.containsKey('vaultKey'), isFalse);

    _expectSuccess(await unlockService.lock());
    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
    expect(session.vaultKey, isNull);

    _expectSuccess(
      await unlockService.unlock(
        userId: user.id,
        masterPassword: masterPassword,
      ),
    );
    expect(vaultSession.vaultData!.logins, [login()]);
    expect(vaultSession.vaultData!.bankCards, [card()]);
    expect(vaultSession.vaultData!.secureNotes, [note()]);
    expect(vaultSession.vaultData!.categories, [
      ...CategoryDefaults.items,
      category(),
    ]);
  }, timeout: kdfTimeout);

  test('failed persistence leaves the previous session state', () async {
    await unlockEmptyVault();
    final gated = _SaveGateVaultRepository(repository);
    final gatedService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: gated,
      vaultSession: vaultSession,
    );

    final first = login();
    _expectSuccess(await gatedService.addLogin(first));
    final previous = vaultSession.vaultData!;

    gated.failNextSave = true;
    _expectFailure<DatabaseFailure>(
      await gatedService.addLogin(login(id: 'login-2')),
    );

    expect(vaultSession.isUnlocked, isTrue);
    expect(vaultSession.vaultData, previous);
    expect(vaultSession.vaultData!.logins, [first]);
  }, timeout: kdfTimeout);

  test('serialization failure leaves the previous session state', () async {
    await unlockEmptyVault();
    _expectSuccess(await dataService.addLogin(login()));
    final previous = vaultSession.vaultData!;

    _expectFailure<ValidationFailure>(
      await dataService.addLogin(login(id: '')),
      forbidden: const [loginPassword],
    );

    expect(vaultSession.vaultData, previous);
  }, timeout: kdfTimeout);

  test('mutations fail when the vault is locked', () async {
    await unlockEmptyVault();
    _expectSuccess(await unlockService.lock());

    _expectFailure<AuthenticationFailure>(await dataService.addLogin(login()));
    _expectFailure<AuthenticationFailure>(
      await dataService.updateLogin(login()),
    );
    _expectFailure<AuthenticationFailure>(
      await dataService.deleteLogin('login-1'),
    );
    _expectFailure<AuthenticationFailure>(
      await dataService.addBankCard(card()),
    );
    _expectFailure<AuthenticationFailure>(
      await dataService.addSecureNote(note()),
    );
    _expectFailure<AuthenticationFailure>(
      await dataService.addCategory(category()),
    );

    expect(vaultSession.isUnlocked, isFalse);
    expect(vaultSession.vaultData, isNull);
  }, timeout: kdfTimeout);

  test('concurrent adds both persist instead of overwriting', () async {
    await unlockEmptyVault();
    final first = login(id: 'login-a');
    final second = login(id: 'login-b');

    final results = await Future.wait([
      dataService.addLogin(first),
      dataService.addLogin(second),
    ]);
    for (final result in results) {
      _expectSuccess(result);
    }

    expect(vaultSession.vaultData!.logins.map((item) => item.id), [
      'login-a',
      'login-b',
    ]);
  }, timeout: kdfTimeout);
}

class _SaveGateVaultRepository implements VaultRepository {
  _SaveGateVaultRepository(this._inner);

  final VaultRepository _inner;
  bool failNextSave = false;

  @override
  Future<Result<Uint8List?>> loadVaultData() => _inner.loadVaultData();

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) {
    if (failNextSave) {
      failNextSave = false;
      return Future<Result<void>>.value(const FailureResult(DatabaseFailure()));
    }
    return _inner.saveVaultData(plaintext);
  }

  @override
  Future<Result<void>> deleteVault() => _inner.deleteVault();
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
