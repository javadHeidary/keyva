import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/category/bindings/category_bindings.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/type/note/viewmodel/note_create_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_edit_viewmodel.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/view/vault_item_navigation.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

class NoteBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    CategoryBindings().dependencies();
    if (!Get.isRegistered<NoteVaultStore>()) {
      Get.put(NoteVaultStore(), permanent: true);
    }
  }

  static VaultItemViewModel _itemViewModel() {
    if (!Get.isRegistered<VaultItemViewModel>()) {
      Get.lazyPut(() => getIt<VaultItemViewModel>());
    }
    return Get.find<VaultItemViewModel>();
  }
}

class NoteCreateBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    final items = NoteBindings._itemViewModel();
    Get.lazyPut(() => NoteCreateViewModel(items: items));
  }
}

class NoteEditBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    final items = NoteBindings._itemViewModel();
    final noteId = vaultRouteItemId();
    Get.lazyPut(() => NoteEditViewModel(noteId: noteId, items: items));
  }
}

class NoteDetailsBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    final noteId = vaultRouteItemId();
    final openedAfterCreate = vaultRouteOpenedAfterCreate();
    Get.lazyPut(
      () => NoteDetailsViewModel(
        noteId: noteId,
        openedAfterCreate: openedAfterCreate,
        shareSheet: getIt<ShareSheetService>(),
      ),
    );
  }
}
