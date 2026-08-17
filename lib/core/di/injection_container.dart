import 'package:get_it/get_it.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';

final GetIt getIt = GetIt.instance;

void initDependencies(HiveDatabase database) {
  getIt.registerSingleton<HiveDatabase>(database);
  getIt.registerLazySingleton<CryptoService>(CryptoServiceImpl.new);
  getIt.registerLazySingleton<KeyManagementService>(
    () => KeyManagementServiceImpl(getIt<CryptoService>()),
  );
}
