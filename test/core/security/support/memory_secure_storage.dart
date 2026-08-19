import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/secure_storage_service.dart';

class MemorySecureStorageService implements SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<Result<void>> write(String key, String value) async {
    values[key] = value;
    return const Success<void>(null);
  }

  @override
  Future<Result<String?>> read(String key) async {
    return Success(values[key]);
  }

  @override
  Future<Result<void>> delete(String key) async {
    values.remove(key);
    return const Success<void>(null);
  }
}
