import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/viewmodel/image_details_viewmodel.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

import '../../vault/support/fake_encrypted_blob_store.dart';
import '../../vault/support/fake_vault_operation_service.dart';
import '../../vault/support/vault_widget_harness.dart';
import 'support/fake_image_gallery_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late FakeEncryptedBlobStore blobs;
  late FakeImageGalleryGateway gallery;
  late ImageGalleryExportService export;
  late VaultHomeViewModel vault;
  late ImageDetailsViewModel viewModel;

  final createdAt = DateTime.utc(2026, 8, 25, 12);
  const blobId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  ImageItem photo() {
    return ImageItem(
      id: 'photo-1',
      folderId: 'folder-1',
      note: null,
      blobId: blobId,
      thumbnailBlobId: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      mimeType: 'image/jpeg',
      width: 20,
      height: 10,
      createdAt: createdAt,
    );
  }

  setUp(() {
    Get.testMode = true;
    operations = FakeVaultOperationService();
    blobs = FakeEncryptedBlobStore();
    gallery = FakeImageGalleryGateway();
    export = ImageGalleryExportService(blobs: blobs, gallery: gallery);
    vault = VaultHomeViewModel(operations: operations);
    blobs.files[blobId] = Uint8List.fromList(const [9, 8, 7]);
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [
        ImageFolder(
          id: 'folder-1',
          title: 'ID',
          categoryId: null,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ],
      images: [photo()],
    );
    vault.vault.value = operations.vault;
    Get.put(vault);
    viewModel = ImageDetailsViewModel(photoId: 'photo-1', export: export);
  });

  tearDown(() {
    AppToast.dismiss();
    Get.reset();
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      vaultTestApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('ignores export until the image has decoded', (tester) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);

    await viewModel.saveToGallery(context);

    expect(viewModel.canExport.value, isFalse);
    expect(gallery.putCount, 0);
  });

  testWidgets('exports once and restores loading state on success', (
    tester,
  ) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);
    viewModel.onImageDecoded(true);

    await viewModel.saveToGallery(context);
    await pumpVaultFrame(tester);

    expect(gallery.putCount, 1);
    expect(viewModel.isExporting.value, isFalse);
    expect(find.text('تصویر با موفقیت در گالری ذخیره شد.'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('prevents a second export while the first is in progress', (
    tester,
  ) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);
    viewModel.onImageDecoded(true);
    gallery.putGate = Completer<void>();

    final first = viewModel.saveToGallery(context);
    await tester.pump();
    expect(viewModel.isExporting.value, isTrue);

    await viewModel.saveToGallery(context);
    expect(gallery.putCount, 1);

    gallery.putGate!.complete();
    await first;
    expect(viewModel.isExporting.value, isFalse);
    AppToast.dismiss();
  });

  testWidgets('restores loading state after a save failure', (tester) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);
    viewModel.onImageDecoded(true);
    gallery.putError = Exception('platform');

    await viewModel.saveToGallery(context);
    await pumpVaultFrame(tester);

    expect(viewModel.isExporting.value, isFalse);
    expect(find.text('ذخیره تصویر در گالری انجام نشد.'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('shows permission message when access is denied', (tester) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);
    viewModel.onImageDecoded(true);
    gallery.accessGranted = false;
    gallery.grantOnRequest = false;

    await viewModel.saveToGallery(context);
    await pumpVaultFrame(tester);

    expect(
      find.text('برای ذخیره تصویر در گالری، دسترسی لازم است.'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('maps decrypt failure without saving', (tester) async {
    setupVaultWidgetSurface(tester);
    final context = await pumpHost(tester);
    viewModel.onImageDecoded(true);
    blobs.readFailure = const CryptoFailure();

    await viewModel.saveToGallery(context);
    await pumpVaultFrame(tester);

    expect(gallery.putCount, 0);
    expect(viewModel.isExporting.value, isFalse);
    expect(find.text('عملیات امنیتی انجام نشد.'), findsOneWidget);
    AppToast.dismiss();
  });
}
