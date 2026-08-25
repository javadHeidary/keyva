import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/view/home_view.dart';
import 'package:keyva/feature/home/view/type_list_item_view.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/image/model/image_add_photo_args.dart';
import 'package:keyva/feature/type/image/service/image_capture_service.dart';
import 'package:keyva/feature/type/image/service/image_photo_service.dart';
import 'package:keyva/feature/type/image/view/image_add_photo_view.dart';
import 'package:keyva/feature/type/image/view/image_folder_create_view.dart';
import 'package:keyva/feature/type/image/view/image_folder_view.dart';
import 'package:keyva/feature/type/image/viewmodel/image_add_photo_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_create_viewmodel.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_viewmodel.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

import '../../vault/support/fake_encrypted_blob_store.dart';
import '../../vault/support/fake_vault_operation_service.dart';
import '../../vault/support/vault_widget_harness.dart';
import 'support/fake_image_capture_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultOperationService operations;
  late FakeEncryptedBlobStore blobs;
  late FakeImageCaptureService capture;
  late VaultHomeViewModel vault;
  late VaultItemViewModel items;
  late HomeController home;
  late ImagePhotoService photos;

  final createdAt = DateTime.utc(2026, 8, 25, 12);

  ImageFolder folder({String title = 'عکس‌های شناسنامه'}) {
    return ImageFolder(
      id: 'folder-1',
      title: title,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ImageItem photo() {
    return ImageItem(
      id: 'photo-1',
      folderId: 'folder-1',
      note: 'should-not-be-a-home-row',
      blobId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      thumbnailBlobId: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      mimeType: 'image/png',
      width: 1,
      height: 1,
      createdAt: createdAt,
    );
  }

  VaultData vaultWithFolder({bool withPhoto = false}) {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
      imageFolders: [folder()],
      images: withPhoto ? [photo()] : const [],
    );
  }

  void ensureControllers() {
    if (!Get.isRegistered<VaultHomeViewModel>()) {
      Get.put(vault, permanent: true);
    }
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.put(items, permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put(home, permanent: true);
    }
  }

  List<GetPage> appPages() {
    return [
      GetPage(
        name: AppRoutes.home,
        page: () => const HomeView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.typeList,
        page: () => TypeListItemView(),
        binding: BindingsBuilder(ensureControllers),
      ),
      GetPage(
        name: AppRoutes.imageFolderCreate,
        page: () => const ImageFolderCreateView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          Get.lazyPut(
            () => ImageFolderCreateViewModel(items: items),
            fenix: true,
          );
        }),
      ),
      GetPage(
        name: AppRoutes.imageFolder,
        page: () => const ImageFolderView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          if (Get.isRegistered<ImageFolderViewModel>()) {
            Get.delete<ImageFolderViewModel>(force: true);
          }
          Get.put(
            ImageFolderViewModel(
              folderId: vaultRouteItemId(),
              capture: capture,
            ),
          );
        }),
      ),
      GetPage(
        name: AppRoutes.imageAddPhoto,
        page: () => const ImageAddPhotoView(),
        binding: BindingsBuilder(() {
          ensureControllers();
          final args = Get.arguments;
          if (Get.isRegistered<ImageAddPhotoViewModel>()) {
            Get.delete<ImageAddPhotoViewModel>(force: true);
          }
          Get.put(
            ImageAddPhotoViewModel(
              args: args is ImageAddPhotoArgs
                  ? args
                  : ImageAddPhotoArgs(
                      folderId: 'folder-1',
                      data: ImageCaptureData(
                        bytes: oneByOnePng,
                        thumbnailBytes: oneByOnePng,
                        mimeType: 'image/png',
                        width: 1,
                        height: 1,
                      ),
                    ),
              photos: photos,
              capture: capture,
            ),
          );
        }),
      ),
    ];
  }

  Future<void> pumpRoutedHome(WidgetTester tester) async {
    setupVaultWidgetSurface(tester);
    await home.loadVault();
    await tester.pumpWidget(
      vaultTestApp(
        home: const HomeView(),
        initialRoute: AppRoutes.home,
        getPages: appPages(),
      ),
    );
    await pumpVaultFrame(tester);
  }

  Future<void> pumpOpenedRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
  }

  setUp(() async {
    Get.testMode = true;
    await getIt.reset();
    operations = FakeVaultOperationService();
    blobs = FakeEncryptedBlobStore();
    capture = FakeImageCaptureService();
    photos = ImagePhotoService(operations: operations, blobs: blobs);
    vault = VaultHomeViewModel(operations: operations);
    items = VaultItemViewModel(operations: operations);
    home = HomeController(vault: vault);
    getIt.registerSingleton<EncryptedBlobStore>(blobs);
    Get.put(vault, permanent: true);
    Get.put(items, permanent: true);
    Get.put(home, permanent: true);
  });

  tearDown(() async {
    Get.reset();
    await getIt.reset();
  });

  testWidgets('home shows folder title not photo', (tester) async {
    operations.vault = vaultWithFolder(withPhoto: true);
    blobs.files[photo().thumbnailBlobId] = oneByOnePng;
    await pumpRoutedHome(tester);

    expect(find.text('عکس‌های شناسنامه'), findsWidgets);
    expect(find.text('1 عکس'), findsWidgets);
    expect(find.text('should-not-be-a-home-row'), findsNothing);
  });

  testWidgets('tapping a folder opens empty contents', (tester) async {
    operations.vault = vaultWithFolder();
    await pumpRoutedHome(tester);

    await tester.tap(find.text('عکس‌های شناسنامه').first);
    await pumpOpenedRoute(tester);

    expect(find.byKey(const Key('vault-image-folder')), findsOneWidget);
    expect(find.byKey(const Key('vault-image-folder-empty')), findsOneWidget);
    expect(find.text('این پوشه خالی است'), findsOneWidget);
  });

  testWidgets('create folder then empty contents', (tester) async {
    operations.vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    await pumpRoutedHome(tester);

    Get.toNamed(AppRoutes.imageFolderCreate);
    await pumpOpenedRoute(tester);
    expect(find.text('ایجاد پوشه تصاویر'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'مدارک');
    await Get.find<ImageFolderCreateViewModel>().submit();
    await pumpOpenedRoute(tester);
    await tester.pump();

    expect(Get.currentRoute, AppRoutes.imageFolder);
    expect(find.byKey(const Key('vault-image-folder')), findsOneWidget);
    expect(find.text('مدارک'), findsWidgets);
    expect(find.text('این پوشه خالی است'), findsOneWidget);
  });

  testWidgets('fake capture saves a photo into the folder', (tester) async {
    operations.vault = vaultWithFolder();
    await pumpRoutedHome(tester);

    await tester.tap(find.text('عکس‌های شناسنامه').first);
    await pumpOpenedRoute(tester);

    await tester.tap(find.byKey(const Key('vault-image-folder-fab')));
    await tester.pumpAndSettle();
    expect(find.text('افزودن تصویر'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('image-source-gallery')));
    await tester.tap(find.byKey(const Key('image-source-gallery')));
    await tester.pumpAndSettle();

    expect(capture.lastSource, ImageCaptureSource.gallery);
    expect(find.byKey(const Key('vault-image-add-photo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('vault-image-save-photo')));
    await pumpOpenedRoute(tester);

    expect(operations.lastAdded, isA<ImageItem>());
    final added = operations.lastAdded! as ImageItem;
    expect(find.byKey(Key('vault-image-photo-${added.id}')), findsOneWidget);
  });
}
