import 'package:hive_ce/hive_ce.dart';
import 'package:keyva/core/exceptions/app_failure.dart';

abstract final class HiveErrorMapper {
  static AppFailure map(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is HiveError) {
      return const DatabaseFailure();
    }
    return const UnknownFailure();
  }
}
