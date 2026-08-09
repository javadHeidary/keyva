import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/type/login/model/login_website_field.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';

abstract class LoginFormViewModel extends GetxController {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final notesController = TextEditingController();

  final isPasswordVisible = false.obs;
  final passwordStrength = 0.0.obs;
  final selectedCategoryId = Rxn<String>();
  final isSubmitting = false.obs;
  final hasPasswordInput = false.obs;
  final websiteFields = <LoginWebsiteField>[].obs;

  String get headerTitle;
  String get submitLabel;
  bool get showDeleteAction => false;

  List<VaultCategory> get selectableCategories {
    if (!Get.isRegistered<HomeController>()) return const [];
    return Get.find<HomeController>().selectableCategories;
  }

  void initFormFields({
    String? categoryId,
    String? title,
    String? username,
    String? password,
    List<String>? websites,
    String? notes,
  }) {
    selectedCategoryId.value = categoryId;
    titleController.text = title ?? '';
    usernameController.text = username ?? '';
    passwordController.text = password ?? '';
    notesController.text = notes ?? '';
    hasPasswordInput.value = passwordController.text.isNotEmpty;
    _updatePasswordStrength(passwordController.text);
    _initWebsiteFields(websites);
  }

  void _initWebsiteFields(List<String>? websites) {
    _disposeWebsiteFields();
    final values = websites?.where((url) => url.trim().isNotEmpty).toList();
    if (values == null || values.isEmpty) {
      websiteFields.add(LoginWebsiteField());
    } else {
      for (final url in values) {
        websiteFields.add(LoginWebsiteField(initial: url));
      }
    }
  }

  void _disposeWebsiteFields() {
    for (final field in websiteFields) {
      field.dispose();
    }
    websiteFields.clear();
  }

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    _updatePasswordStrength(passwordController.text);
  }

  void _updatePasswordStrength(String value) {
    passwordStrength.value = calculateLoginPasswordStrength(value);
    hasPasswordInput.value = value.isNotEmpty;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void addWebsiteField() {
    websiteFields.add(LoginWebsiteField());
  }

  void removeWebsiteField(int index) {
    if (index < 0 || index >= websiteFields.length) return;
    if (websiteFields.length == 1) {
      websiteFields.first.controller.clear();
      return;
    }
    websiteFields[index].dispose();
    websiteFields.removeAt(index);
  }

  List<String> collectNormalizedWebsites() {
    final result = <String>[];
    for (final field in websiteFields) {
      final raw = field.controller.text.trim();
      if (raw.isEmpty) continue;
      final normalized = normalizeWebsiteUrl(raw);
      if (normalized != null) result.add(normalized);
    }
    return result;
  }

  void generatePassword() {
    passwordController.text = generateLoginPassword();
    _updatePasswordStrength(passwordController.text);
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'عنوان ورود الزامی است';
    }
    if (value.trim().length < 2) {
      return 'عنوان باید حداقل ۲ کاراکتر باشد';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'نام کاربری الزامی است';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'رمز عبور الزامی است';
    }
    if (value.length < 4) {
      return 'رمز عبور باید حداقل ۴ کاراکتر باشد';
    }
    return null;
  }

  String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (normalizeWebsiteUrl(value) == null) {
      return 'آدرس وب‌سایت معتبر نیست';
    }
    return null;
  }

  bool validateForm() => formKey.currentState?.validate() ?? false;

  Future<void> submit();

  void handleDelete();

  @override
  void onClose() {
    passwordController.removeListener(_onPasswordChanged);
    _disposeWebsiteFields();
    titleController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
