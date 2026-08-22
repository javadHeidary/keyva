import 'package:keyva/core/exceptions/result.dart';

abstract interface class ScreenProtectionService {
  bool get isEnabled;

  Future<Result<void>> setEnabled(bool enabled);

  Future<Result<void>> applyPersisted();
}
