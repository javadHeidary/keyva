import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/screen_protection_service.dart';

class FakeScreenProtectionService implements ScreenProtectionService {
  @override
  bool isEnabled = false;

  int setEnabledCount = 0;
  int applyPersistedCount = 0;
  bool? lastEnabled;
  AppFailure? setEnabledFailure;
  AppFailure? applyPersistedFailure;

  @override
  Future<Result<void>> setEnabled(bool enabled) async {
    setEnabledCount++;
    lastEnabled = enabled;
    final failure = setEnabledFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    isEnabled = enabled;
    return const Success(null);
  }

  @override
  Future<Result<void>> applyPersisted() async {
    applyPersistedCount++;
    final failure = applyPersistedFailure;
    if (failure != null) {
      return FailureResult(failure);
    }
    return const Success(null);
  }
}
