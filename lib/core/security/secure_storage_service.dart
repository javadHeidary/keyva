import 'package:keyva/core/exceptions/result.dart';

abstract interface class SecureStorageService {
  Future<Result<void>> write(String key, String value);

  Future<Result<String?>> read(String key);

  Future<Result<void>> delete(String key);
}
