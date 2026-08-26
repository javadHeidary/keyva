import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/note/model/note_item_model.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';

class NoteVaultStore extends GetxService {
  final RxList<NoteItem> items = <NoteItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (items.isEmpty) {
      items.add(
        NoteItem(
          id: '3',
          categoryId: 'personal',
          title: 'کدهای بازیابی',
          body:
              'کدهای بازیابی حساب را اینجا نگه دارید.\nاین یادداشت فقط یک نمونه است.',
          createdAt: DateTime(2024, 1, 20, 11, 15),
        ),
      );
      _syncHomeVaultList();
    }
  }

  NoteItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void add(NoteItem item) {
    items.add(item);
    _syncHomeVaultList();
  }

  void update(NoteItem item) {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    items[index] = item;
    _syncHomeVaultList();
  }

  void moveToTrash(String id) {
    items.removeWhere((entry) => entry.id == id);
    _syncHomeVaultList();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().incrementTrashCount();
    }
  }

  void clearCategoryId(String categoryId) {
    var changed = false;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.categoryId == categoryId) {
        items[i] = item.copyWith(clearCategoryId: true);
        changed = true;
      }
    }
    if (changed) _syncHomeVaultList();
  }

  VaultListItem toVaultListItem(NoteItem item) {
    return VaultListItem(
      id: item.id,
      type: VaultItemType.secureNote,
      title: item.title,
      subtitle: previewNoteBody(item.body),
      categoryId: item.categoryId ?? '',
    );
  }

  void _syncHomeVaultList() {
    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    home.syncNoteItems(items.map(toVaultListItem).toList());
  }
}
