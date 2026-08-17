import 'package:get_it/get_it.dart';
import 'package:keyva/core/database/hive_database.dart';

final GetIt getIt = GetIt.instance;

void initDependencies(HiveDatabase database) {
  getIt.registerSingleton<HiveDatabase>(database);
}
