import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/backup/model/backup_preview.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/backup/service/backup_service_impl.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_data_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

import '../../core/security/support/fast_key_management_service.dart';

void main() {
  late CryptoService crypto;
  late KeyManagementService keys;
  late SessionService session;
  late VaultSession vaultSession;
  late _MemoryVaultRepository vaults;
  late VaultSerializer serializer;
  late VaultDataService dataService;
  late VaultOperationService operations;
  late BackupService backup;

  const backupPassword = 'backup-pass-1';
  const username = 'TEST_USERNAME';
  const password = 'TEST_SECRET_123';
  const note = 'VERY_SECRET_NOTE';
  const cardNumber = 'TEST_CARD_NUMBER';
  const cvv = 'TEST_CVV';

  final createdAt = DateTime.utc(2026, 8, 1, 9, 30, 15);
  final updatedAt = DateTime.utc(2026, 8, 2, 10, 45, 20);

  VaultData sampleVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-1',
          title: 'Work mail',
          username: username,
          password: password,
          website: 'https://mail.example',
          notes: 'mailbox',
          categoryId: 'cat-1',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      bankCards: [
        BankCardItem(
          id: 'card-1',
          title: 'Main card',
          cardNumber: cardNumber,
          cardHolder: 'TEST HOLDER',
          expiryDate: '12/29',
          cvv: cvv,
          bankName: 'Test Bank',
          notes: 'primary',
          categoryId: 'cat-1',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      secureNotes: [
        SecureNoteItem(
          id: 'note-1',
          title: 'Safe note',
          content: note,
          categoryId: 'cat-1',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      categories: [
        CategoryItem(
          id: 'cat-1',
          name: 'Work',
          icon: 'work',
          createdAt: createdAt,
        ),
      ],
    );
  }

  VaultData otherVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-other',
          title: 'Other',
          username: 'other',
          password: 'other-pass',
          website: null,
          notes: null,
          categoryId: null,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  Future<void> unlock(VaultData vault) async {
    session.setAuthenticated(
      userId: 'user-1',
      username: 'owner',
      vaultKey: Uint8List.fromList(List<int>.generate(32, (index) => index + 1)),
    );
    await vaultSession.unlock(vault);
  }

  setUp(() async {
    crypto = CryptoServiceImpl();
    keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    vaults = _MemoryVaultRepository();
    serializer = VaultSerializerImpl();
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: vaults,
      vaultSession: vaultSession,
    );
    operations = VaultOperationServiceImpl(
      vaultData: dataService,
      vaultSession: vaultSession,
    );
    backup = BackupServiceImpl(
      operations: operations,
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
    );
  });

  test('round-trips VaultData through backup and restore', () async {
    final original = sampleVault();
    await unlock(original);

    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    expect(
      jsonDecode(utf8.decode(bytes))['formatVersion'],
      2,
    );

    await vaultSession.unlock(otherVault());
    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    _expectSuccess(await backup.restoreVault(plan.vault));

    expect(vaultSession.vaultData, original);
    expect(vaults.saveCount, 1);
  });

  test('backup bytes do not contain sentinel plaintext', () async {
    await unlock(sampleVault());
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final haystack = utf8.decode(bytes, allowMalformed: true);
    expect(haystack.contains(username), isFalse);
    expect(haystack.contains(password), isFalse);
    expect(haystack.contains(note), isFalse);
    expect(haystack.contains(cardNumber), isFalse);
    expect(haystack.contains(cvv), isFalse);
    final object = jsonDecode(utf8.decode(bytes)) as Map;
    expect(object.containsKey('wrappedVaultKey'), isFalse);
    expect(object.containsKey('masterPassword'), isFalse);
    expect(object.containsKey('vaultKey'), isFalse);
    expect(
      object.keys,
      unorderedEquals(<String>[
        'formatVersion',
        'kdfSalt',
        'kdfParameters',
        'nonce',
        'ciphertext',
        'authenticationTag',
      ]),
    );
  });

  test('wrong backup password does not change the vault', () async {
    final original = sampleVault();
    await unlock(original);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );

    final result = await backup.decryptBackup(
      bytes: bytes,
      backupPassword: 'wrong-backup',
    );
    expect(result, isA<FailureResult<BackupRestorePlan>>());
    expect(
      (result as FailureResult<BackupRestorePlan>).failure,
      isA<WrongBackupPasswordFailure>(),
    );
    expect(vaultSession.vaultData, original);
    expect(vaults.saveCount, 0);
  });

  test('corrupted backup is rejected and vault stays unchanged', () async {
    final original = sampleVault();
    await unlock(original);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    bytes[bytes.length - 3] = bytes[bytes.length - 3] ^ 0xff;

    final validated = backup.validateEnvelope(bytes);
    final decrypted = await backup.decryptBackup(
      bytes: bytes,
      backupPassword: backupPassword,
    );
    expect(
      validated.isFailure || decrypted.isFailure,
      isTrue,
    );
    expect(vaultSession.vaultData, original);
    expect(vaults.saveCount, 0);
  });

  test('unsupported backup version is rejected', () async {
    final original = sampleVault();
    await unlock(original);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final object = Map<String, Object?>.from(
      jsonDecode(utf8.decode(bytes)) as Map,
    );
    object['formatVersion'] = 99;
    final unsupported = Uint8List.fromList(utf8.encode(jsonEncode(object)));

    final result = backup.validateEnvelope(unsupported);
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<UnsupportedBackupVersionFailure>(),
    );
    expect(vaultSession.vaultData, original);
  });

  test('empty vault backup and restore works', () async {
    final empty = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await unlock(empty);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    await vaultSession.unlock(otherVault());
    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    _expectSuccess(await backup.restoreVault(plan.vault));
    expect(vaultSession.vaultData, empty);
  });

  test('persistence failure leaves the previous vault intact', () async {
    final original = sampleVault();
    await unlock(original);
    _expectSuccess(await dataService.replaceVault(original));
    final persisted = Uint8List.fromList(vaults.stored!);
    final originalKey = Uint8List.fromList(session.vaultKey!);

    vaults.saveFailure = const DatabaseFailure();
    final failed = await backup.restoreVault(otherVault());

    expect(failed, isA<FailureResult<void>>());
    expect(
      (failed as FailureResult<void>).failure,
      isA<BackupRestorePersistenceFailure>(),
    );
    expect(vaultSession.vaultData, original);
    expect(vaults.stored, persisted);
    expect(session.vaultKey, originalKey);
  });

  test('restore keeps the current session vault key', () async {
    await unlock(sampleVault());
    final sessionKey = session.vaultKey!;
    final originalValue = Uint8List.fromList(sessionKey);
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    _expectSuccess(await backup.restoreVault(plan.vault));
    expect(identical(session.vaultKey, sessionKey), isTrue);
    expect(session.vaultKey, originalValue);
  });

  test('decryptBackup works without an authenticated session', () async {
    await unlock(sampleVault());
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    session.clear();
    await vaultSession.lock();

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    expect(plan.vault, sampleVault());
    expect(vaults.saveCount, 0);

    final restored = await backup.restoreVault(plan.vault);
    expect(restored, isA<FailureResult<void>>());
    expect(
      (restored as FailureResult<void>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(vaults.saveCount, 0);
  });

  test('decryptBackup reports increasing stages and 100 only on success', () async {
    await unlock(sampleVault());
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final reports = <RestoreProgress>[];
    final plan = _expectSuccess(
      await backup.decryptBackup(
        bytes: bytes,
        backupPassword: backupPassword,
        onProgress: reports.add,
      ),
    );
    expect(plan.vault, sampleVault());
    _expectIncreasingProgress(reports);
    expect(reports.first.percent, 0);
    expect(reports.last.percent, 100);
    expect(reports.last.stage, RestoreProgressStage.completed);
    expect(
      reports.map((report) => report.stage),
      containsAll(<RestoreProgressStage>[
        RestoreProgressStage.starting,
        RestoreProgressStage.validating,
        RestoreProgressStage.derivingKey,
        RestoreProgressStage.decrypting,
        RestoreProgressStage.deserializing,
        RestoreProgressStage.completed,
      ]),
    );
  });

  test('decryptBackup failure never reports 100', () async {
    await unlock(sampleVault());
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final reports = <RestoreProgress>[];
    final result = await backup.decryptBackup(
      bytes: bytes,
      backupPassword: 'wrong-backup',
      onProgress: reports.add,
    );
    expect(result, isA<FailureResult<BackupRestorePlan>>());
    expect(reports, isNotEmpty);
    expect(reports.any((report) => report.percent >= 100), isFalse);
    expect(reports.any((report) => report.isCompleted), isFalse);
  });

  test('restoreVault reports persist progress without claiming 100', () async {
    await unlock(sampleVault());
    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    final reports = <RestoreProgress>[];
    _expectSuccess(await backup.restoreVault(plan.vault, onProgress: reports.add));
    expect(reports, isNotEmpty);
    expect(reports.first.stage, RestoreProgressStage.persisting);
    expect(reports.first.percent, 40);
    expect(reports.any((report) => report.isCompleted), isFalse);
    expect(reports.any((report) => report.percent > 100), isFalse);
  });
}

class _MemoryVaultRepository implements VaultRepository {
  Uint8List? stored;
  AppFailure? saveFailure;
  int saveCount = 0;

  @override
  Future<Result<Uint8List?>> loadVaultData() async => Success(stored);

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) async {
    saveCount++;
    final failure = saveFailure;
    if (failure != null) {
      saveFailure = null;
      return FailureResult(failure);
    }
    stored = Uint8List.fromList(plaintext);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteVault() async {
    stored = null;
    return const Success<void>(null);
  }
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectIncreasingProgress(List<RestoreProgress> reports) {
  expect(reports, isNotEmpty);
  var previous = -1;
  for (final report in reports) {
    expect(report.percent, inInclusiveRange(0, 100));
    expect(report.percent, greaterThanOrEqualTo(previous));
    previous = report.percent;
  }
}
