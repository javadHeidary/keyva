import 'dart:typed_data';

import 'package:keyva/core/session/authenticated_session.dart';

abstract interface class SessionService {
  AuthenticatedSession? get current;

  bool get isAuthenticated;

  Uint8List? get vaultKey;

  void setAuthenticated({
    required String userId,
    required String username,
    required Uint8List vaultKey,
  });

  void updateUsername(String username);

  void clear();
}
