import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/home/model/vault_models.dart';

class VaultItemRouteArgs {
  const VaultItemRouteArgs({
    required this.id,
    this.openedAfterCreate = false,
  });

  final String id;
  final bool openedAfterCreate;
}

String vaultItemDetailsRoute(VaultItemType type) {
  return switch (type) {
    VaultItemType.login => AppRoutes.loginDetails,
    VaultItemType.bankCard => AppRoutes.bankCardDetails,
    VaultItemType.secureNote => AppRoutes.noteDetails,
    VaultItemType.image => AppRoutes.imageFolder,
  };
}

String vaultRouteItemId() {
  final args = Get.arguments;
  if (args is VaultItemRouteArgs) {
    return args.id;
  }
  return args is String ? args : '';
}

bool vaultRouteOpenedAfterCreate() {
  final args = Get.arguments;
  return args is VaultItemRouteArgs && args.openedAfterCreate;
}

String? vaultRouteCategoryId() {
  final args = Get.arguments;
  if (args is String && args.isNotEmpty) {
    return args;
  }
  return null;
}

void openVaultItemDetails(VaultItemType type, String id) {
  Get.toNamed(vaultItemDetailsRoute(type), arguments: id);
}

void openVaultTypeList(VaultItemType type) {
  Get.toNamed(AppRoutes.typeList, arguments: type);
}

void openCreatedVaultItem({
  required VaultItemType type,
  required String id,
}) {
  Get.offNamedUntil(
    AppRoutes.typeList,
    (route) =>
        route.settings.name == AppRoutes.shell ||
        route.settings.name == AppRoutes.home,
    arguments: type,
  );
  SchedulerBinding.instance.addPostFrameCallback((_) {
    Get.toNamed(
      vaultItemDetailsRoute(type),
      arguments: VaultItemRouteArgs(id: id, openedAfterCreate: true),
    );
  });
}
