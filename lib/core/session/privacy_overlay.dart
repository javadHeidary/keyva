import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/session/app_lock_controller.dart';

class PrivacyOverlay extends StatelessWidget {
  const PrivacyOverlay({super.key});

  static const overlayKey = Key('privacy-overlay');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    return AbsorbPointer(
      child: SizedBox.expand(
        child: ColoredBox(key: overlayKey, color: color),
      ),
    );
  }
}

class PrivacyOverlayLayer extends StatelessWidget {
  const PrivacyOverlayLayer({required this.child, this.controller, super.key});

  final Widget child;
  final AppLockController? controller;

  @override
  Widget build(BuildContext context) {
    final lock = controller ?? Get.find<AppLockController>();
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Obx(() {
          final visible = lock.overlayVisible.value;
          return IgnorePointer(
            ignoring: !visible,
            child: visible ? const PrivacyOverlay() : const SizedBox.shrink(),
          );
        }),
      ],
    );
  }
}
