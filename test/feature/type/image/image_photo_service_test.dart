import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/service/image_photo_service.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

import '../../vault/support/fake_encrypted_blob_store.dart';
import '../../vault/support/fake_vault_operation_service.dart';

void main() {
  late FakeVaultOperationService operations;
  late FakeEncryptedBlobStore blobs;
  late ImagePhotoService photos;

  final createdAt = DateTime.utc(2026, 8, 25);

  ImageFolder folder() {
    return ImageFolder(
      id: 'folder-1',
      title: 'ID photos',
      categoryId: null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUp(() {
    operations = FakeVaultOperationService();
    blobs = FakeEncryptedBlobStore();
    photos = ImagePhotoService(operations: operations, blobs: blobs);
  });

  test('writes blobs then persists the photo', () async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [folder()],
    );

    _expectSuccess(
      await photos.addPhoto(
        folderId: 'folder-1',
        bytes: Uint8List.fromList([1, 2, 3]),
        thumbnailBytes: Uint8List.fromList([4]),
        mimeType: 'image/jpeg',
        width: 20,
        height: 10,
      ),
    );

    expect(blobs.files.length, 2);
    expect(operations.lastAdded, isA<ImageItem>());
    final item = operations.lastAdded! as ImageItem;
    expect(item.folderId, 'folder-1');
    expect(blobs.files.containsKey(item.blobId), isTrue);
    expect(blobs.files.containsKey(item.thumbnailBlobId), isTrue);
  });

  test('rolls back blobs when vault save fails', () async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [folder()],
    );
    operations.addFailure = const ValidationFailure();

    final result = await photos.addPhoto(
      folderId: 'folder-1',
      bytes: Uint8List.fromList([1, 2, 3]),
      thumbnailBytes: Uint8List.fromList([4]),
      mimeType: 'image/jpeg',
      width: 20,
      height: 10,
    );

    expect(result, isA<FailureResult<void>>());
    expect(blobs.files, isEmpty);
  });

  test('rejects a photo without a folder', () async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );

    final result = await photos.addPhoto(
      folderId: 'missing',
      bytes: Uint8List.fromList([1]),
      thumbnailBytes: Uint8List.fromList([2]),
      mimeType: 'image/jpeg',
      width: 20,
      height: 10,
    );

    expect(result, isA<FailureResult<void>>());
    expect(blobs.files, isEmpty);
    expect(operations.addCount, 0);
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}
