import 'package:get/get.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/backup/service/backup_file_service.dart';
import 'package:keyva/feature/backup/service/backup_service.dart';
import 'package:keyva/feature/backup/viewmodel/backup_viewmodel.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';

class BackupBindings extends Bindings {
  BackupBindings({this.createAccountMode = false});

  final bool createAccountMode;

  @override
  void dependencies() {
    Get.lazyPut(() => getIt<BackupViewModel>());
    Get.lazyPut(
      () => RestoreViewModel(
        backup: getIt<BackupService>(),
        files: getIt<BackupFileService>(),
        session: getIt<SessionService>(),
        mode: createAccountMode
            ? RestoreMode.createAccount
            : RestoreMode.replaceExisting,
      ),
    );
  }
}
