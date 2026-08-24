import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/feature/home/viewmodel/home_viewmodel.dart';
import 'package:keyva/feature/settings/model/user_profile.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';

import '../auth/support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository auth;
  late HomeController home;
  late SettingsViewModel settings;

  setUp(() {
    Get.testMode = true;
    auth = FakeAuthRepository()..storedUser = _user(username: 'علی');
    home = HomeController(auth: auth);
    settings = SettingsViewModel(auth: auth);
    Get.put(home);
  });

  tearDown(Get.reset);

  test('Home and Settings load the persisted name', () async {
    await home.loadAccountProfile();
    await settings.loadProfile();

    expect(home.accountOwnerName.value, 'علی');
    expect(settings.profile.value.name, 'علی');
  });

  test('updating profile persists and refreshes Home and Settings', () async {
    await home.loadAccountProfile();
    await settings.loadProfile();

    final saved = await settings.updateProfile(
      const UserProfile(name: 'رضا'),
    );

    expect(saved, isTrue);
    expect(auth.updateProfileCount, 1);
    expect(auth.storedUser!.username, 'رضا');
    expect(settings.profile.value.name, 'رضا');
    expect(home.accountOwnerName.value, 'رضا');

    final restoredHome = HomeController(auth: auth);
    final restoredSettings = SettingsViewModel(auth: auth);
    await restoredHome.loadAccountProfile();
    await restoredSettings.loadProfile();

    expect(restoredHome.accountOwnerName.value, 'رضا');
    expect(restoredSettings.profile.value.name, 'رضا');
  });
}

UserRecord _user({required String username}) {
  return UserRecord(
    id: 'user-1',
    username: username,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    kdfSalt: Uint8List.fromList(List<int>.filled(16, 1)),
    kdfParameters: const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    ),
    wrappedVaultKey: WrappedVaultKey(
      version: SecurityConstants.wrappedKeyVersion,
      nonce: Uint8List.fromList(List<int>.filled(12, 2)),
      ciphertext: Uint8List.fromList(List<int>.filled(48, 3)),
      authenticationTag: Uint8List.fromList(List<int>.filled(16, 4)),
    ),
    securitySettings: SecuritySettings.initial(),
  );
}
