import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/backup/service/backup_service_impl.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_data_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_operation_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

import '../../core/security/support/fast_key_management_service.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late SessionServiceImpl session;
  late VaultSessionImpl vaultSession;
  late VaultSerializerImpl serializer;
  late _InterceptingVaultRepository vaults;
  late VaultDataServiceImpl dataService;
  late BackupServiceImpl backup;

  const userId = 'user-1';
  final createdAt = DateTime.utc(2026, 8, 1, 9, 30);
  final updatedAt = DateTime.utc(2026, 8, 2, 10, 45);

  VaultData vaultA() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-a',
          title: 'Vault A',
          username: 'user-a',
          password: 'secret-a',
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

  VaultData vaultB() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: [
        LoginItem(
          id: 'login-b',
          title: 'Vault B',
          username: 'user-b',
          password: 'secret-b',
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

  Future<void> authenticate(Uint8List vaultKey) async {
    session.setAuthenticated(
      userId: userId,
      username: 'owner',
      vaultKey: vaultKey,
    );
  }

  Future<VaultData> loadPersistedVault() async {
    final loaded = _expectSuccess(await vaults.loadVaultData());
    expect(loaded, isNotNull);
    return _expectSuccess(await serializer.deserialize(loaded!));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_backup_lock_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    final crypto = CryptoServiceImpl();
    final keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    serializer = VaultSerializerImpl();
    final inner = VaultRepositoryImpl(
      vaults: HiveVaultDataSource(database!),
      crypto: crypto,
      session: session,
    );
    vaults = _InterceptingVaultRepository(inner);
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: vaults,
      vaultSession: vaultSession,
    );
    backup = BackupServiceImpl(
      operations: VaultOperationServiceImpl(
        vaultData: dataService,
        vaultSession: vaultSession,
      ),
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
    );

    final vaultKey = Uint8List.fromList(
      List<int>.generate(SecurityConstants.vaultKeyLength, (index) => index + 1),
    );
    await authenticate(vaultKey);
    await vaultSession.unlock(vaultA());
    _expectSuccess(await dataService.replaceVault(vaultA()));
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Hive persistence failure keeps Vault A, session A, and vault key', () async {
    final originalKey = Uint8List.fromList(session.vaultKey!);
    vaults.nextSaveFailure = const DatabaseFailure();

    final restored = await backup.restoreVault(vaultB());

    expect(restored, isA<FailureResult<void>>());
    expect(
      (restored as FailureResult<void>).failure,
      isA<BackupRestorePersistenceFailure>(),
    );
    expect(vaultSession.vaultData, vaultA());
    expect(session.vaultKey, originalKey);
    expect(await loadPersistedVault(), vaultA());
    expect(database!.vaults.get(userId), isNotNull);
  });

  test('lock before persistence keeps Hive Vault A and does not apply Vault B', () async {
    final originalKey = Uint8List.fromList(session.vaultKey!);
    vaults.beforeSave = () async {
      await vaultSession.lock();
      session.clear();
    };

    final restored = await backup.restoreVault(vaultB());

    expect(restored, isA<FailureResult<void>>());
    expect(
      (restored as FailureResult<void>).failure,
      isA<AuthenticationFailure>(),
    );
    expect(vaultSession.isUnlocked, isFalse);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);

    await authenticate(Uint8List.fromList(originalKey));
    expect(session.vaultKey, originalKey);
    expect(await loadPersistedVault(), vaultA());
  });

  test(
    'lock after saveVaultData does not rehydrate VaultSession with restored plaintext',
    () async {
      final originalKey = Uint8List.fromList(session.vaultKey!);
      vaults.afterSuccessfulSave = () async {
        await vaultSession.lock();
        session.clear();
      };

      final restored = await backup.restoreVault(vaultB());

      expect(restored, isA<FailureResult<void>>());
      expect(
        (restored as FailureResult<void>).failure,
        isA<AuthenticationFailure>(),
      );
      expect(vaultSession.isUnlocked, isFalse);
      expect(vaultSession.vaultData, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(session.vaultKey, isNull);

      await authenticate(Uint8List.fromList(originalKey));
      expect(session.vaultKey, originalKey);
      expect(await loadPersistedVault(), vaultB());
    },
  );
}

class _InterceptingVaultRepository implements VaultRepository {
  _InterceptingVaultRepository(this._inner);

  final VaultRepository _inner;
  AppFailure? nextSaveFailure;
  Future<void> Function()? beforeSave;
  Future<void> Function()? afterSuccessfulSave;

  @override
  Future<Result<Uint8List?>> loadVaultData() => _inner.loadVaultData();

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) async {
    final before = beforeSave;
    if (before != null) {
      await before();
    }
    final failure = nextSaveFailure;
    if (failure != null) {
      nextSaveFailure = null;
      return FailureResult(failure);
    }
    final saved = await _inner.saveVaultData(plaintext);
    if (saved is Success<void>) {
      final after = afterSuccessfulSave;
      if (after != null) {
        await after();
      }
    }
    return saved;
  }

  @override
  Future<Result<void>> deleteVault() => _inner.deleteVault();
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
