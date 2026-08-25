import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/settings/model/theme_preference.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/main.dart';

import 'support/fake_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSettingsRepository repository;

  setUp(() {
    Get.testMode = true;
    repository = FakeSettingsRepository();
  });

  tearDown(Get.reset);

  test('setThemePreference persists and a new ViewModel restores it', () async {
    final first = SettingsViewModel(repository: repository);
    await first.setThemePreference(ThemePreference.dark);

    expect(first.themePreference.value, ThemePreference.dark);
    expect(repository.stored, ThemePreference.dark);

    final second = SettingsViewModel(repository: repository);
    await second.loadThemePreference();
    expect(second.themePreference.value, ThemePreference.dark);
  });

  test('KeyvaApp uses the provided themeMode instead of system', () {
    const app = KeyvaApp(themeMode: ThemeMode.dark);
    expect(app.themeMode, ThemeMode.dark);
  });
}
