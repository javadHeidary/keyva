import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginWebsiteField {
  LoginWebsiteField({String? initial}) {
    controller = TextEditingController(text: initial ?? '');
    preview.value = controller.text;
    controller.addListener(_syncPreview);
  }

  final String id = DateTime.now().microsecondsSinceEpoch.toString();
  late final TextEditingController controller;
  final RxString preview = ''.obs;

  void _syncPreview() {
    preview.value = controller.text;
  }

  void dispose() {
    controller.removeListener(_syncPreview);
    controller.dispose();
  }
}
