import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/secure_storage_service.dart';

class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<Result<void>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return const Success<void>(null);
    } catch (_) {
      return const FailureResult(UnknownFailure());
    }
  }

  @override
  Future<Result<String?>> read(String key) async {
    try {
      return Success(await _storage.read(key: key));
    } catch (_) {
      return const FailureResult(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return const Success<void>(null);
    } catch (_) {
      return const FailureResult(UnknownFailure());
    }
  }
}
