import 'package:keyva/core/exceptions/app_failure.dart';

abstract final class CryptoErrorMapper {
  static AppFailure map(Object error) {
    if (error is AppFailure) {
      return error;
    }
    return const CryptoFailure();
  }
}
