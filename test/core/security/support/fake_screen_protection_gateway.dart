import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/screen_protection_gateway.dart';

class FakeScreenProtectionGateway implements ScreenProtectionGateway {
  bool? lastEnabled;
  final List<bool> calls = [];
  AppFailure? failure;

  @override
  Future<Result<void>> setSecure(bool enabled) async {
    calls.add(enabled);
    lastEnabled = enabled;
    final currentFailure = failure;
    if (currentFailure != null) {
      return FailureResult(currentFailure);
    }
    return const Success(null);
  }
}
