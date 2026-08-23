import 'dart:typed_data';

import 'package:keyva/core/session/authenticated_session.dart';
import 'package:keyva/core/session/session_service.dart';

class SessionServiceImpl implements SessionService {
  AuthenticatedSession? _current;
  Uint8List? _vaultKey;

  @override
  AuthenticatedSession? get current => _current;

  @override
  bool get isAuthenticated => _current != null;

  @override
  Uint8List? get vaultKey => _vaultKey;

  @override
  void setAuthenticated({
    required String userId,
    required String username,
    required Uint8List vaultKey,
  }) {
    _clearVaultKey();
    _current = AuthenticatedSession(userId: userId, username: username);
    _vaultKey = vaultKey;
  }

  @override
  void updateUsername(String username) {
    final current = _current;
    if (current == null) {
      return;
    }
    _current = AuthenticatedSession(
      userId: current.userId,
      username: username,
    );
  }

  @override
  void clear() {
    _clearVaultKey();
    _current = null;
  }

  void _clearVaultKey() {
    final key = _vaultKey;
    if (key != null) {
      key.fillRange(0, key.length, 0);
    }
    _vaultKey = null;
  }
}
