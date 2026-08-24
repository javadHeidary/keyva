import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/feature/password_generator/data/password_generator_settings_store.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/model/password_generator_settings.dart';
import 'package:keyva/feature/password_generator/util/password_generator_engine.dart';
import 'package:keyva/feature/password_generator/util/password_generator_strength.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class PasswordGeneratorViewModel extends GetxController {
  final generatedPassword = ''.obs;
  final strength = 0.0.obs;

  PasswordGeneratorSettingsStore get _settingsStore =>
      Get.find<PasswordGeneratorSettingsStore>();

  PasswordHistoryStore get _historyStore => Get.find<PasswordHistoryStore>();

  PasswordGeneratorSettings get settings => _settingsStore.settings.value;

  Rx<PasswordGeneratorSettings> get settingsRx => _settingsStore.settings;

  @override
  void onInit() {
    super.onInit();
    ever(_settingsStore.settings, (_) => regenerate());
    regenerate();
  }

  void regenerate() {
    try {
      final password = generateSecurePassword(settings);
      generatedPassword.value = password;
      strength.value = calculatePasswordGeneratorStrength(password);
    } on PasswordGeneratorException catch (e) {
      generatedPassword.value = '';
      strength.value = 0;
      final context = Get.context;
      if (context != null) {
        AppToast.error(context, title: 'تولید رمز', message: e.message);
      }
    }
  }

  Future<void> setLength(double value) async {
    final length = value.round().clamp(
      PasswordGeneratorSettings.minLength,
      PasswordGeneratorSettings.maxLength,
    );
    await _updateSettings(settings.copyWith(length: length));
    regenerate();
  }

  Future<void> toggleUppercase(bool value) async {
    await _updateSettings(settings.copyWith(uppercase: value));
    regenerate();
  }

  Future<void> toggleLowercase(bool value) async {
    await _updateSettings(settings.copyWith(lowercase: value));
    regenerate();
  }

  Future<void> toggleNumbers(bool value) async {
    await _updateSettings(settings.copyWith(numbers: value));
    regenerate();
  }

  Future<void> toggleSymbols(bool value) async {
    await _updateSettings(settings.copyWith(symbols: value));
    regenerate();
  }

  Future<void> toggleExcludeSimilar(bool value) async {
    await _updateSettings(settings.copyWith(excludeSimilar: value));
    regenerate();
  }

  Future<void> _updateSettings(PasswordGeneratorSettings value) async {
    if (!_hasActiveGroup(value)) {
      final context = Get.context;
      if (context != null) {
        AppToast.error(
          context,
          title: 'تولید رمز',
          message: 'حداقل یک نوع کاراکتر باید فعال باشد',
        );
      }
      return;
    }
    await _settingsStore.update(value);
  }

  bool _hasActiveGroup(PasswordGeneratorSettings value) {
    return value.uppercase || value.lowercase || value.numbers || value.symbols;
  }

  String get strengthLabel => passwordGeneratorStrengthLabel(strength.value);

  int get strengthPercent => passwordGeneratorStrengthPercent(strength.value);

  Color strengthColor(BuildContext context) =>
      loginPasswordStrengthColor(context, strength.value);

  Future<void> copyPassword(BuildContext context) async {
    final password = generatedPassword.value;
    if (password.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: password));
    await _historyStore.addFromCopy(password);
    if (!context.mounted) return;
    AppToast.success(context, title: 'کپی', message: 'رمز عبور کپی شد');
  }

  void openHistoryMenu() {
    Get.toNamed(AppRoutes.passwordGeneratorHistory);
  }
}
