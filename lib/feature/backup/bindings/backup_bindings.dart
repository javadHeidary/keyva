import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/feature/backup/viewmodel/backup_viewmodel.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';

class BackupBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => getIt<BackupViewModel>());
    Get.lazyPut(() => getIt<RestoreViewModel>());
  }
}
