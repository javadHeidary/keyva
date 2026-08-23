import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/session/session_service_impl.dart';

void main() {
  late SessionServiceImpl session;

  setUp(() {
    session = SessionServiceImpl();
  });

  test('starts locked with no session', () {
    expect(session.current, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
  });

  test('setAuthenticated stores the user id and vault key in memory', () {
    final vaultKey = Uint8List.fromList(
      List<int>.generate(SecurityConstants.vaultKeyLength, (i) => i + 1),
    );

    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: vaultKey,
    );

    expect(session.isAuthenticated, isTrue);
    expect(session.current, isNotNull);
    expect(session.current!.userId, 'user-1');
    expect(session.current!.username, 'علی');
    expect(session.vaultKey, vaultKey);
  });

  test('clear drops the session and zeros in-memory vault key bytes', () {
    final vaultKey = Uint8List.fromList(
      List<int>.generate(SecurityConstants.vaultKeyLength, (i) => i + 1),
    );

    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: vaultKey,
    );
    session.clear();

    expect(session.current, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(vaultKey, Uint8List(SecurityConstants.vaultKeyLength));
  });

  test('updateUsername changes the display name and keeps the vault key', () {
    final vaultKey = Uint8List.fromList(
      List<int>.generate(SecurityConstants.vaultKeyLength, (i) => i + 1),
    );

    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: vaultKey,
    );
    session.updateUsername('رضا');

    expect(session.current!.userId, 'user-1');
    expect(session.current!.username, 'رضا');
    expect(session.vaultKey, vaultKey);
  });
}
