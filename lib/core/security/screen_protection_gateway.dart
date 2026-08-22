import 'package:keyva/core/exceptions/result.dart';

abstract interface class ScreenProtectionGateway {
  Future<Result<void>> setSecure(bool enabled);
}
