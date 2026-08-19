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
import 'package:keyva/core/security/biometric_gateway.dart';
import 'package:keyva/core/security/biometric_service.dart';
import 'package:keyva/core/security/biometric_service_impl.dart';
import 'package:keyva/core/security/local_auth_biometric_gateway.dart';
import 'package:keyva/core/security/pin_service.dart';
import 'package:keyva/core/security/pin_service_impl.dart';
import 'package:keyva/core/security/secure_storage_service.dart';
import 'package:keyva/core/security/secure_storage_service_impl.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/repository/vault_repository_impl.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_data_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service_impl.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service.dart';
import 'package:keyva/feature/vault/service/vault_unlock_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';
import 'package:keyva/feature/vault/viewmodel/vault_home_viewmodel.dart';
import 'package:keyva/feature/vault/viewmodel/vault_item_viewmodel.dart';

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
  getIt.registerLazySingleton<SecureStorageService>(
    SecureStorageServiceImpl.new,
  );
  getIt.registerLazySingleton<BiometricGateway>(
    LocalAuthBiometricGateway.new,
  );
  getIt.registerLazySingleton<PinService>(
    () => PinServiceImpl(
      crypto: getIt<CryptoService>(),
      keys: getIt<KeyManagementService>(),
      storage: getIt<SecureStorageService>(),
      users: getIt<UserDataSource>(),
      session: getIt<SessionService>(),
      database: getIt<HiveDatabase>(),
    ),
  );
  getIt.registerLazySingleton<BiometricService>(
    () => BiometricServiceImpl(
      gateway: getIt<BiometricGateway>(),
      keys: getIt<KeyManagementService>(),
      storage: getIt<SecureStorageService>(),
      users: getIt<UserDataSource>(),
      session: getIt<SessionService>(),
    ),
  );
  getIt.registerLazySingleton<VaultSerializer>(VaultSerializerImpl.new);
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      users: getIt<UserDataSource>(),
      crypto: getIt<CryptoService>(),
      keys: getIt<KeyManagementService>(),
      session: getIt<SessionService>(),
      database: getIt<HiveDatabase>(),
    ),
  );
  getIt.registerLazySingleton<VaultRepository>(
    () => VaultRepositoryImpl(
      vaults: getIt<VaultDataSource>(),
      crypto: getIt<CryptoService>(),
      session: getIt<SessionService>(),
    ),
  );
  getIt.registerLazySingleton<VaultSession>(VaultSessionImpl.new);
  getIt.registerLazySingleton<VaultUnlockService>(
    () => VaultUnlockServiceImpl(
      auth: getIt<AuthRepository>(),
      vaults: getIt<VaultRepository>(),
      serializer: getIt<VaultSerializer>(),
      vaultSession: getIt<VaultSession>(),
      pin: getIt<PinService>(),
      biometric: getIt<BiometricService>(),
    ),
  );
  getIt.registerLazySingleton<VaultDataService>(
    () => VaultDataServiceImpl(
      serializer: getIt<VaultSerializer>(),
      vaults: getIt<VaultRepository>(),
      vaultSession: getIt<VaultSession>(),
    ),
  );
  getIt.registerLazySingleton<VaultOperationService>(
    () => VaultOperationServiceImpl(
      vaultData: getIt<VaultDataService>(),
      vaultSession: getIt<VaultSession>(),
    ),
  );
  getIt.registerFactory<VaultHomeViewModel>(
    () => VaultHomeViewModel(operations: getIt<VaultOperationService>()),
  );
  getIt.registerFactory<VaultItemViewModel>(
    () => VaultItemViewModel(operations: getIt<VaultOperationService>()),
  );
}
