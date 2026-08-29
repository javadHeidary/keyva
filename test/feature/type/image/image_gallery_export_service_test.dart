import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/service/image_gallery_gateway.dart';
import 'package:keyva/feature/vault/model/image_item.dart';

import '../../vault/support/fake_encrypted_blob_store.dart';
import 'support/fake_image_gallery_gateway.dart';

void main() {
  late FakeEncryptedBlobStore blobs;
  late FakeImageGalleryGateway gallery;
  late ImageGalleryExportService export;
  late Directory trackedTemp;

  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  const blobId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  setUp(() {
    blobs = FakeEncryptedBlobStore();
    gallery = FakeImageGalleryGateway();
    trackedTemp = Directory.systemTemp.createTempSync('keyva_gallery_export_');
    export = ImageGalleryExportService(
      blobs: blobs,
      gallery: gallery,
      now: () => DateTime.utc(2026, 8, 29, 10, 11, 12),
    );
  });

  tearDown(() {
    if (trackedTemp.existsSync()) {
      trackedTemp.deleteSync(recursive: true);
    }
  });

  test('decrypts vault bytes and saves them in memory', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);

    _expectSuccess(
      await export.export(blobId: blobId, mimeType: 'image/jpeg'),
    );

    expect(gallery.putCount, 1);
    expect(gallery.lastBytes, bytes);
    expect(gallery.lastName, 'keyva_1787998272000_jpg');
    expect(blobs.files[blobId], bytes);
    expect(gallery.writtenPaths, isEmpty);
    expect(trackedTemp.listSync(), isEmpty);
  });

  test('returns permission denied then permanently denied', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    gallery.accessGranted = false;
    gallery.grantOnRequest = false;

    final first = await export.export(blobId: blobId, mimeType: 'image/jpeg');
    expect(first, isA<FailureResult<void>>());
    final firstFailure =
        (first as FailureResult<void>).failure as GalleryPermissionDeniedFailure;
    expect(firstFailure.permanentlyDenied, isFalse);
    expect(gallery.putCount, 0);
    expect(blobs.files[blobId], bytes);

    final second = await export.export(blobId: blobId, mimeType: 'image/jpeg');
    final secondFailure =
        (second as FailureResult<void>).failure as GalleryPermissionDeniedFailure;
    expect(secondFailure.permanentlyDenied, isTrue);
  });

  test('returns decrypt failure without touching the gallery', () async {
    blobs.readFailure = const CryptoFailure();

    final result = await export.export(blobId: blobId, mimeType: 'image/jpeg');

    expect((result as FailureResult<void>).failure, isA<CryptoFailure>());
    expect(gallery.putCount, 0);
    expect(gallery.requestCount, 0);
  });

  test('treats missing or empty image data as invalid', () async {
    final missing = await export.export(blobId: blobId, mimeType: 'image/jpeg');
    expect((missing as FailureResult<void>).failure, isA<ValidationFailure>());

    blobs.files[blobId] = Uint8List(0);
    final empty = await export.export(blobId: blobId, mimeType: 'image/jpeg');
    expect((empty as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(gallery.putCount, 0);
  });

  test('maps gallery plugin errors to a save failure', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    gallery.putError = Exception('platform');

    final result = await export.export(blobId: blobId, mimeType: 'image/png');

    expect((result as FailureResult<void>).failure, isA<GallerySaveFailure>());
    expect(gallery.lastName, 'keyva_1787998272000_png');
    expect(blobs.files[blobId], bytes);
    expect(trackedTemp.listSync(), isEmpty);
  });

  test('maps access denied during save as permanently denied', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    gallery.putError = const ImageGalleryAccessDenied();

    final result = await export.export(blobId: blobId, mimeType: 'image/jpeg');
    final failure =
        (result as FailureResult<void>).failure as GalleryPermissionDeniedFailure;
    expect(failure.permanentlyDenied, isTrue);
  });

  ImageItem photo({
    required String id,
    required String blobId,
    String mimeType = 'image/jpeg',
  }) {
    return ImageItem(
      id: id,
      folderId: 'folder-1',
      note: 'secret-note',
      blobId: blobId,
      thumbnailBlobId: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      mimeType: mimeType,
      width: 2,
      height: 2,
      createdAt: DateTime.utc(2026, 8, 25),
    );
  }

  test('exports every folder image sequentially with unique names', () async {
    const a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const c = 'cccccccccccccccccccccccccccccccc';
    blobs.files[a] = Uint8List.fromList([1, 2]);
    blobs.files[c] = Uint8List.fromList([3, 4]);
    final snapshot = Map<String, Uint8List>.from(blobs.files);
    final progress = <(int, int)>[];

    final result = await export.exportFolder(
      images: [
        photo(id: '1', blobId: a),
        photo(id: '2', blobId: c, mimeType: 'image/png'),
      ],
      onProgress: (current, total) => progress.add((current, total)),
    );

    final data =
        (result as Success<ImageGalleryFolderExportResult>).data;
    expect(data.saved, 2);
    expect(data.total, 2);
    expect(gallery.putCount, 2);
    expect(gallery.names, [
      'keyva_1787998272000_0_jpg',
      'keyva_1787998272000_1_png',
    ]);
    expect(progress, [(1, 2), (2, 2)]);
    expect(blobs.files.length, snapshot.length);
    expect(trackedTemp.listSync(), isEmpty);
  });

  test('exports a single folder image', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    final result = await export.exportFolder(
      images: [photo(id: '1', blobId: blobId)],
    );
    expect(
      (result as Success<ImageGalleryFolderExportResult>).data.saved,
      1,
    );
    expect(gallery.putCount, 1);
  });

  test('does not touch the gallery for an empty folder', () async {
    final result = await export.exportFolder(images: const []);
    expect(
      (result as Success<ImageGalleryFolderExportResult>).data.total,
      0,
    );
    expect(gallery.putCount, 0);
    expect(gallery.hasAccessCount, 0);
  });

  test('skips decrypt and save failures and continues', () async {
    const good = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const missing = 'dddddddddddddddddddddddddddddddd';
    const later = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
    blobs.files[good] = Uint8List.fromList([1]);
    blobs.files[later] = Uint8List.fromList([2]);
    gallery.failAtPutCount = 2;

    final result = await export.exportFolder(
      images: [
        photo(id: '1', blobId: good),
        photo(id: '2', blobId: missing),
        photo(id: '3', blobId: later),
      ],
    );

    final data =
        (result as Success<ImageGalleryFolderExportResult>).data;
    expect(data.saved, 1);
    expect(data.total, 3);
    expect(gallery.putCount, 2);
  });

  test('stops the folder export when permission is denied', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    gallery.accessGranted = false;
    gallery.grantOnRequest = false;

    final result = await export.exportFolder(
      images: [photo(id: '1', blobId: blobId)],
    );
    expect(
      (result as FailureResult<ImageGalleryFolderExportResult>).failure,
      isA<GalleryPermissionDeniedFailure>(),
    );
    expect(gallery.putCount, 0);
  });

  test('rejects a second export while one is in progress', () async {
    blobs.files[blobId] = Uint8List.fromList(bytes);
    gallery.putGate = Completer<void>();

    final first = export.exportFolder(
      images: [photo(id: '1', blobId: blobId)],
    );
    await Future<void>.delayed(Duration.zero);
    final second = await export.exportFolder(
      images: [photo(id: '2', blobId: blobId)],
    );
    expect(
      (second as FailureResult<ImageGalleryFolderExportResult>).failure,
      isA<GalleryExportBusyFailure>(),
    );

    gallery.putGate!.complete();
    final done = await first;
    expect(
      (done as Success<ImageGalleryFolderExportResult>).data.saved,
      1,
    );
  });
}

void _expectSuccess(Result<void> result) {
  expect(result, isA<Success<void>>());
}
