import 'package:get_it/get_it.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/hive_vault_data_source.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/database/vault_data_source.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';

final GetIt getIt = GetIt.instance;

void initDependencies(HiveDatabase database) {
  getIt.registerSingleton<HiveDatabase>(database);
  getIt.registerLazySingleton<UserDataSource>(
    () => HiveUserDataSource(getIt<HiveDatabase>()),
  );
  getIt.registerLazySingleton<VaultDataSource>(
    () => HiveVaultDataSource(getIt<HiveDatabase>()),
  );
  getIt.registerLazySingleton<CryptoService>(CryptoServiceImpl.new);
  getIt.registerLazySingleton<KeyManagementService>(
    () => KeyManagementServiceImpl(getIt<CryptoService>()),
  );
  getIt.registerLazySingleton<SessionService>(SessionServiceImpl.new);
  getIt.registerLazySingleton<VaultSerializer>(VaultSerializerImpl.new);
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      users: getIt<UserDataSource>(),
      crypto: getIt<CryptoService>(),
      keys: getIt<KeyManagementService>(),
      session: getIt<SessionService>(),
    ),
  );
  getIt.registerLazySingleton<VaultRepository>(
    () => VaultRepositoryImpl(
      vaults: getIt<VaultDataSource>(),
      crypto: getIt<CryptoService>(),
      session: getIt<SessionService>(),
    ),
  );
}
