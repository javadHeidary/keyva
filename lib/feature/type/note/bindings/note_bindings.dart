import 'package:get/get.dart';
import 'package:keyva/feature/type/note/data/note_vault_store.dart';
import 'package:keyva/feature/type/note/viewmodel/note_create_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_details_viewmodel.dart';
import 'package:keyva/feature/type/note/viewmodel/note_edit_viewmodel.dart';

class NoteBindings extends Bindings {
  @override
  void dependencies() {
    _ensureStore();
  }

  static void _ensureStore() {
    if (!Get.isRegistered<NoteVaultStore>()) {
      Get.put(NoteVaultStore(), permanent: true);
    }
  }
}

class NoteCreateBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    Get.lazyPut(() => NoteCreateViewModel());
  }
}

class NoteEditBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    final noteId = Get.arguments as String? ?? '';
    Get.lazyPut(() => NoteEditViewModel(noteId: noteId));
  }
}

class NoteDetailsBindings extends Bindings {
  @override
  void dependencies() {
    NoteBindings._ensureStore();
    final noteId = Get.arguments as String? ?? '';
    Get.lazyPut(() => NoteDetailsViewModel(noteId: noteId));
  }
}
