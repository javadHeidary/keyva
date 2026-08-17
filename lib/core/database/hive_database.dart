import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_error_mapper.dart';
import 'package:keyva/core/database/hive_registrar.g.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/exceptions/app_failure.dart';

class HiveDatabase {
  HiveDatabase._({
    required this.users,
    required this.vaults,
    required this.appSettings,
  });

  final Box<UserRecord> users;
  final Box<VaultRecord> vaults;
  final Box<dynamic> appSettings;

  static bool _adaptersRegistered = false;

  static Future<HiveDatabase> initialize({String? testDatabasePath}) async {
    try {
      if (testDatabasePath != null) {
        Hive.init(testDatabasePath);
      } else {
        await Hive.initFlutter();
      }

      if (!_adaptersRegistered) {
        Hive.registerAdapters();
        _adaptersRegistered = true;
      }

      final users = await Hive.openBox<UserRecord>(HiveBoxNames.users);
      final vaults = await Hive.openBox<VaultRecord>(HiveBoxNames.vaults);
      final appSettings = await Hive.openBox<dynamic>(HiveBoxNames.appSettings);

      await _ensureDatabaseVersion(appSettings);

      return HiveDatabase._(
        users: users,
        vaults: vaults,
        appSettings: appSettings,
      );
    } catch (error) {
      try {
        await Hive.close();
      } catch (_) {}
      throw HiveErrorMapper.map(error);
    }
  }

  static Future<void> _ensureDatabaseVersion(Box<dynamic> settings) async {
    final version = settings.get(HiveSettingsKeys.databaseVersion);
    if (version == null) {
      await settings.put(
        HiveSettingsKeys.databaseVersion,
        DatabaseConfig.currentVersion,
      );
      return;
    }

    if (version is! int || version != DatabaseConfig.currentVersion) {
      throw const DatabaseFailure();
    }
  }

  Future<void> close() => Hive.close();
}
