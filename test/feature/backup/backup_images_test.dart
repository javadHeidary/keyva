import 'dart:convert';
import 'dart:io';
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
import 'package:keyva/feature/backup/model/backup_envelope.dart';
import 'package:keyva/feature/backup/serialization/backup_envelope_codec.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/backup/service/backup_service_impl.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store_impl.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
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
  late Directory blobDir;
  late CryptoService crypto;
  late KeyManagementService keys;
  late SessionService session;
  late VaultSession vaultSession;
  late _MemoryVaultRepository vaults;
  late VaultSerializer serializer;
  late VaultDataService dataService;
  late VaultOperationService operations;
  late EncryptedBlobStoreImpl blobs;
  late BackupService backup;

  const backupPassword = 'backup-pass-1';
  final createdAt = DateTime.utc(2026, 8, 25, 12);

  const blobId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const thumbId = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  final photoBytes = Uint8List.fromList([11, 22, 33, 44]);
  final thumbBytes = Uint8List.fromList([55, 66]);

  VaultData imageVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [
        ImageFolder(
          id: 'folder-1',
          title: 'ID photos',
          categoryId: null,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ],
      images: [
        ImageItem(
          id: 'photo-1',
          folderId: 'folder-1',
          note: null,
          blobId: blobId,
          thumbnailBlobId: thumbId,
          mimeType: 'image/jpeg',
          width: 20,
          height: 10,
          createdAt: createdAt,
        ),
      ],
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
    blobDir = await Directory.systemTemp.createTemp('keyva_backup_blobs_');
    crypto = CryptoServiceImpl();
    keys = FastKeyManagementService(KeyManagementServiceImpl(crypto));
    session = SessionServiceImpl();
    vaultSession = VaultSessionImpl();
    vaults = _MemoryVaultRepository();
    serializer = VaultSerializerImpl();
    blobs = EncryptedBlobStoreImpl(
      crypto: crypto,
      session: session,
      supportDirectory: () async => blobDir,
    );
    dataService = VaultDataServiceImpl(
      serializer: serializer,
      vaults: vaults,
      vaultSession: vaultSession,
    );
    operations = VaultOperationServiceImpl(
      vaultData: dataService,
      vaultSession: vaultSession,
      blobs: blobs,
    );
    backup = BackupServiceImpl(
      operations: operations,
      vaultData: dataService,
      serializer: serializer,
      crypto: crypto,
      keys: keys,
      blobs: blobs,
    );
  });

  tearDown(() async {
    if (blobDir.existsSync()) {
      await blobDir.delete(recursive: true);
    }
  });

  test('create backup includes folders photos and bytes', () async {
    await unlock(imageVault());
    _expectSuccess(
      await blobs.writeWithId(blobId: blobId, plaintext: photoBytes),
    );
    _expectSuccess(
      await blobs.writeWithId(blobId: thumbId, plaintext: thumbBytes),
    );

    final bytes = _expectSuccess(
      await backup.createBackup(backupPassword: backupPassword),
    );
    expect(jsonDecode(utf8.decode(bytes))['formatVersion'], 2);

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    expect(plan.preview.countLines, contains('پوشه تصویر: 1'));
    expect(plan.preview.countLines, contains('تصویر: 1'));
    expect(plan.vault.imageFolders.single.title, 'ID photos');
    expect(plan.imageBlobs[blobId], photoBytes);
    expect(plan.imageBlobs[thumbId], thumbBytes);

    session.setAuthenticated(
      userId: 'user-1',
      username: 'owner',
      vaultKey: Uint8List.fromList(List<int>.generate(32, (index) => 9 - index)),
    );
    await vaultSession.unlock(
      VaultData(
        version: VaultData.currentVersion,
        logins: const [],
        bankCards: const [],
        secureNotes: const [],
        categories: const [],
      ),
    );

    _expectSuccess(
      await backup.restoreVault(plan.vault, imageBlobs: plan.imageBlobs),
    );
    blobs.clearCache();
    expect(_expectSuccess(await blobs.read(blobId)), photoBytes);
    expect(_expectSuccess(await blobs.read(thumbId)), thumbBytes);
    expect(vaultSession.vaultData!.imageFolders.single.title, 'ID photos');
  });

  test('missing blob fails closed and writes no backup', () async {
    await unlock(imageVault());
    final result = await backup.createBackup(backupPassword: backupPassword);
    expect(result, isA<FailureResult<Uint8List>>());
    expect(
      (result as FailureResult<Uint8List>).failure,
      isA<BackupExportFailure>(),
    );
  });

  test('v1 backup without images still restores', () async {
    final empty = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await unlock(empty);
    final plaintext = _expectSuccess(await serializer.serialize(empty));
    final salt = keys.generateSalt();
    final parameters = keys.defaultKdfParameters();
    final derived = _expectSuccess(
      await crypto.deriveKey(
        masterPassword: backupPassword,
        salt: salt,
        parameters: parameters,
      ),
    );
    final encrypted = _expectSuccess(
      await crypto.encrypt(plaintext: plaintext, key: derived),
    );
    derived.fillRange(0, derived.length, 0);
    final bytes = _expectSuccess(
      BackupEnvelopeCodec.encode(
        BackupEnvelope(
          formatVersion: 1,
          kdfSalt: salt,
          kdfParameters: parameters,
          nonce: encrypted.nonce,
          ciphertext: encrypted.ciphertext,
          authenticationTag: encrypted.authenticationTag,
        ),
      ),
    );

    final plan = _expectSuccess(
      await backup.decryptBackup(bytes: bytes, backupPassword: backupPassword),
    );
    expect(plan.imageBlobs, isEmpty);
    _expectSuccess(
      await backup.restoreVault(plan.vault, imageBlobs: plan.imageBlobs),
    );
    expect(vaultSession.vaultData!.imageFolders, isEmpty);
    expect(vaultSession.vaultData!.images, isEmpty);
  });

  test('restoreVault persist failure keeps previous vault and blobs', () async {
    final current = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [
        ImageFolder(
          id: 'folder-old',
          title: 'Current photos',
          categoryId: null,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ],
      images: [
        ImageItem(
          id: 'photo-old',
          folderId: 'folder-old',
          note: null,
          blobId: blobId,
          thumbnailBlobId: thumbId,
          mimeType: 'image/jpeg',
          width: 8,
          height: 8,
          createdAt: createdAt,
        ),
      ],
    );
    await unlock(current);
    _expectSuccess(
      await blobs.writeWithId(blobId: blobId, plaintext: photoBytes),
    );
    _expectSuccess(
      await blobs.writeWithId(blobId: thumbId, plaintext: thumbBytes),
    );
    _expectSuccess(await dataService.replaceVault(current));

    vaults.nextSaveFailure = const DatabaseFailure();
    const restoredBlobId = 'cccccccccccccccccccccccccccccccc';
    const restoredThumbId = 'dddddddddddddddddddddddddddddddd';
    final restored = imageVault().images.single;
    final incoming = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: imageVault().imageFolders,
      images: [
        ImageItem(
          id: restored.id,
          folderId: restored.folderId,
          note: restored.note,
          blobId: restoredBlobId,
          thumbnailBlobId: restoredThumbId,
          mimeType: restored.mimeType,
          width: restored.width,
          height: restored.height,
          createdAt: restored.createdAt,
        ),
      ],
    );

    final result = await backup.restoreVault(
      incoming,
      imageBlobs: {
        restoredBlobId: Uint8List.fromList([9, 9, 9]),
        restoredThumbId: Uint8List.fromList([8, 8]),
      },
    );
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure,
      isA<BackupRestorePersistenceFailure>(),
    );
    expect(vaultSession.vaultData!.imageFolders.single.title, 'Current photos');
    blobs.clearCache();
    expect(_expectSuccess(await blobs.read(blobId)), photoBytes);
    expect(_expectSuccess(await blobs.read(thumbId)), thumbBytes);
    expect(await blobs.read(restoredBlobId), isA<FailureResult<Uint8List>>());
  });
}

class _MemoryVaultRepository implements VaultRepository {
  Uint8List? stored;
  AppFailure? nextSaveFailure;

  @override
  Future<Result<Uint8List?>> loadVaultData() async => Success(stored);

  @override
  Future<Result<void>> saveVaultData(Uint8List plaintext) async {
    final failure = nextSaveFailure;
    if (failure != null) {
      nextSaveFailure = null;
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
