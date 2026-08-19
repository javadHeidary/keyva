import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/routes/app_routing.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/view_model/auth_startup_viewmodel.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late SessionServiceImpl session;
  late FakeAuthRepository auth;
  late AuthStartupViewModel startup;

  setUp(() {
    session = SessionServiceImpl();
    auth = FakeAuthRepository();
    startup = AuthStartupViewModel(session: session, auth: auth);
  });

  test('unlocked session restores the protected shell', () async {
    session.setAuthenticated(
      userId: 'user-1',
      username: 'test',
      vaultKey: Uint8List(32),
    );

    expect(await startup.resolveInitialRoute(), AppRoutes.shell);
  });

  test('locked device with an account goes to Unlock', () async {
    auth.anyAccount = true;
    expect(await startup.resolveInitialRoute(), AppRoutes.authLogin);
  });

  test('locked device with no account goes to onboarding', () async {
    auth.anyAccount = false;
    expect(await startup.resolveInitialRoute(), AppRoutes.onBoarding);
  });

  test('account lookup failure fails closed to Unlock', () async {
    auth = FakeHasAccountFailure();
    startup = AuthStartupViewModel(session: session, auth: auth);
    expect(await startup.resolveInitialRoute(), AppRoutes.authLogin);
  });
}

class FakeHasAccountFailure extends FakeAuthRepository {
  @override
  Future<Result<bool>> hasAnyAccount() async {
    return const FailureResult(DatabaseFailure());
  }
}
